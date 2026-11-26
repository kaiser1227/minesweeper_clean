// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

void main() {
  final outputDir = Directory('/Users/akm/minesweeper_clean/assets/audio');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  // 1. Click: subtle wooden/bubble click (45ms)
  saveWav('${outputDir.path}/click.wav', generateClick(0.045, 950));

  // 2. Flag: crisp metallic snap chime (75ms)
  saveWav('${outputDir.path}/flag.wav', generateFlag(0.075));

  // 3. Unflag: soft pop down (50ms)
  saveWav('${outputDir.path}/unflag.wav', generateUnflag(0.050));

  // 4. Cascade: water drop tone (110ms)
  saveWav('${outputDir.path}/cascade.wav', generateCascade(0.110));

  // 5. Hint: sparkling light bell (180ms)
  saveWav('${outputDir.path}/hint.wav', generateHint(0.180));

  // 6. Win: warm major arpeggio chime (500ms)
  saveWav('${outputDir.path}/win.wav', generateWin(0.500));

  // 7. Explode: soft low-pass thud (250ms)
  saveWav('${outputDir.path}/explode.wav', generateExplode(0.250));

  print('Audio files generated successfully in ${outputDir.path}');
}

List<int> generateClick(double duration, double freq) {
  const sampleRate = 44100;
  final numSamples = (sampleRate * duration).round();
  final samples = Float64List(numSamples);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final progress = i / numSamples;
    final env = exp(-progress * 22);
    // Sine + subtle high click
    final s1 = sin(2 * pi * freq * t);
    final s2 = sin(2 * pi * (freq * 1.6) * t) * 0.4;
    samples[i] = (s1 + s2) * env * 0.7;
  }
  return encodePcm16Wav(samples, sampleRate);
}

List<int> generateFlag(double duration) {
  const sampleRate = 44100;
  final numSamples = (sampleRate * duration).round();
  final samples = Float64List(numSamples);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final progress = i / numSamples;
    final env = exp(-progress * 15);
    final s1 = sin(2 * pi * 1480 * t);
    final s2 = sin(2 * pi * 2960 * t) * 0.5;
    samples[i] = (s1 + s2) * env * 0.6;
  }
  return encodePcm16Wav(samples, sampleRate);
}

List<int> generateUnflag(double duration) {
  const sampleRate = 44100;
  final numSamples = (sampleRate * duration).round();
  final samples = Float64List(numSamples);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final progress = i / numSamples;
    final env = exp(-progress * 18);
    final freq = 700 - (350 * progress);
    samples[i] = sin(2 * pi * freq * t) * env * 0.6;
  }
  return encodePcm16Wav(samples, sampleRate);
}

List<int> generateCascade(double duration) {
  const sampleRate = 44100;
  final numSamples = (sampleRate * duration).round();
  final samples = Float64List(numSamples);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final progress = i / numSamples;
    final env = exp(-progress * 10);
    final s1 = sin(2 * pi * 1046.5 * t); // C6
    final s2 = sin(2 * pi * 2093.0 * t) * 0.3; // C7
    samples[i] = (s1 + s2) * env * 0.5;
  }
  return encodePcm16Wav(samples, sampleRate);
}

List<int> generateHint(double duration) {
  const sampleRate = 44100;
  final numSamples = (sampleRate * duration).round();
  final samples = Float64List(numSamples);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final progress = i / numSamples;
    final env = exp(-progress * 7);
    final s1 = sin(2 * pi * 659.25 * t); // E5
    final s2 = sin(2 * pi * 987.77 * t) * 0.6; // B5
    final s3 = sin(2 * pi * 1318.5 * t) * 0.4; // E6
    samples[i] = (s1 + s2 + s3) * env * 0.4;
  }
  return encodePcm16Wav(samples, sampleRate);
}

List<int> generateWin(double duration) {
  const sampleRate = 44100;
  final numSamples = (sampleRate * duration).round();
  final samples = Float64List(numSamples);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final progress = i / numSamples;
    final env = exp(-progress * 5);
    final s1 = sin(2 * pi * 523.25 * t); // C5
    final s2 = sin(2 * pi * 659.25 * t) * 0.8; // E5
    final s3 = sin(2 * pi * 783.99 * t) * 0.7; // G5
    final s4 = sin(2 * pi * 1046.50 * t) * 0.5; // C6
    samples[i] = (s1 + s2 + s3 + s4) * env * 0.3;
  }
  return encodePcm16Wav(samples, sampleRate);
}

List<int> generateExplode(double duration) {
  const sampleRate = 44100;
  final numSamples = (sampleRate * duration).round();
  final samples = Float64List(numSamples);
  final rand = Random(42);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final progress = i / numSamples;
    final env = exp(-progress * 9);
    final freq = 120 - (70 * progress);
    final bass = sin(2 * pi * freq * t);
    final noise = (rand.nextDouble() * 2 - 1) * 0.3 * exp(-progress * 14);
    samples[i] = (bass + noise) * env * 0.8;
  }
  return encodePcm16Wav(samples, sampleRate);
}

List<int> encodePcm16Wav(Float64List samples, int sampleRate) {
  final numSamples = samples.length;
  final subChunk2Size = numSamples * 2; // 16-bit mono
  final chunkSize = 36 + subChunk2Size;

  final bdata = ByteData(44 + subChunk2Size);

  // RIFF
  bdata.setUint8(0, 0x52); // 'R'
  bdata.setUint8(1, 0x49); // 'I'
  bdata.setUint8(2, 0x46); // 'F'
  bdata.setUint8(3, 0x46); // 'F'
  bdata.setUint32(4, chunkSize, Endian.little);
  bdata.setUint8(8, 0x57);  // 'W'
  bdata.setUint8(9, 0x41);  // 'A'
  bdata.setUint8(10, 0x56); // 'V'
  bdata.setUint8(11, 0x45); // 'E'

  // 'fmt '
  bdata.setUint8(12, 0x66); // 'f'
  bdata.setUint8(13, 0x6D); // 'm'
  bdata.setUint8(14, 0x74); // 't'
  bdata.setUint8(15, 0x20); // ' '
  bdata.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
  bdata.setUint16(20, 1, Endian.little);  // AudioFormat (1 = PCM)
  bdata.setUint16(22, 1, Endian.little);  // NumChannels (1 = Mono)
  bdata.setUint32(24, sampleRate, Endian.little); // SampleRate
  bdata.setUint32(28, sampleRate * 2, Endian.little); // ByteRate
  bdata.setUint16(32, 2, Endian.little);  // BlockAlign
  bdata.setUint16(34, 16, Endian.little); // BitsPerSample

  // 'data'
  bdata.setUint8(36, 0x64); // 'd'
  bdata.setUint8(37, 0x61); // 'a'
  bdata.setUint8(38, 0x74); // 't'
  bdata.setUint8(39, 0x61); // 'a'
  bdata.setUint32(40, subChunk2Size, Endian.little);

  // PCM samples
  int offset = 44;
  for (int i = 0; i < numSamples; i++) {
    double s = samples[i].clamp(-1.0, 1.0);
    int intSample = (s * 32767).round();
    bdata.setInt16(offset, intSample, Endian.little);
    offset += 2;
  }

  return bdata.buffer.asUint8List();
}

void saveWav(String path, List<int> bytes) {
  File(path).writeAsBytesSync(bytes);
}
