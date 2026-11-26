package com.cleangames.minesweeper.minesweeper_clean

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "minesweeper/vibration"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
                vibratorManager.defaultVibrator
            } else {
                @Suppress("DEPRECATION")
                getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            }

            when (call.method) {
                "vibrate" -> {
                    val duration = (call.argument<Int>("duration") ?: 50).toLong()
                    val amplitude = call.argument<Int>("amplitude") ?: -1

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val effect = if (amplitude in 1..255 && vibrator.hasAmplitudeControl()) {
                            VibrationEffect.createOneShot(duration, amplitude)
                        } else {
                            VibrationEffect.createOneShot(duration, VibrationEffect.DEFAULT_AMPLITUDE)
                        }
                        vibrator.vibrate(effect)
                    } else {
                        @Suppress("DEPRECATION")
                        vibrator.vibrate(duration)
                    }
                    result.success(true)
                }
                "pattern" -> {
                    val timingsArg = call.argument<List<Number>>("timings")
                    val amplitudesArg = call.argument<List<Number>>("amplitudes")

                    val timings = timingsArg?.map { it.toLong() }?.toLongArray() ?: longArrayOf(0L, 80L, 80L, 150L, 100L, 70L)
                    val amplitudes = amplitudesArg?.map { it.toInt() }?.toIntArray()

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && amplitudes != null && amplitudes.size == timings.size && vibrator.hasAmplitudeControl()) {
                        val effect = VibrationEffect.createWaveform(timings, amplitudes, -1)
                        vibrator.vibrate(effect)
                    } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val effect = VibrationEffect.createWaveform(timings, -1)
                        vibrator.vibrate(effect)
                    } else {
                        @Suppress("DEPRECATION")
                        vibrator.vibrate(timings, -1)
                    }
                    result.success(true)
                }
                "cancel" -> {
                    vibrator.cancel()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
