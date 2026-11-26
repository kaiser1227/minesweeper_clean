import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/audio_controller.dart';
import 'core/haptic_controller.dart';
import 'core/localization.dart';
import 'core/preferences_manager.dart';
import 'core/theme_manager.dart';
import 'engine/board_generator.dart';
import 'engine/game_state.dart';
import 'ui/board_view.dart';
import 'ui/header_bar.dart';
import 'ui/language_dialog.dart';
import 'ui/stats_dialog.dart';
import 'ui/victory_dialog.dart';
import 'ui/virtual_tutorial_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set immersive fullscreen & dark system UI style
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final prefs = PreferencesManager();
  await prefs.init();

  runApp(MinesweeperApp(prefs: prefs));
}

class MinesweeperApp extends StatefulWidget {
  final PreferencesManager prefs;

  const MinesweeperApp({super.key, required this.prefs});

  @override
  State<MinesweeperApp> createState() => _MinesweeperAppState();
}

class _MinesweeperAppState extends State<MinesweeperApp> {
  late AppThemeMode _themeMode;
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.prefs.isDarkTheme
        ? AppThemeMode.oledDark
        : AppThemeMode.cleanPaper;
    _locale = widget.prefs.savedLocale;
  }

  void _changeLocale(Locale? locale) {
    setState(() {
      _locale = locale;
    });
    widget.prefs.setLocale(locale);
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == AppThemeMode.oledDark
          ? AppThemeMode.cleanPaper
          : AppThemeMode.oledDark;
    });
    widget.prefs.setDarkTheme(_themeMode == AppThemeMode.oledDark);
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme(_themeMode);

    return MaterialApp(
      title: 'Minesweeper Clean',
      debugShowCheckedModeBanner: false,
      theme: theme.toThemeData(),
      locale: _locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MinesweeperScreen(
        prefs: widget.prefs,
        theme: theme,
        onToggleTheme: _toggleTheme,
        onLocaleChanged: _changeLocale,
        currentLocale: _locale,
      ),
    );
  }
}

class MinesweeperScreen extends StatefulWidget {
  final PreferencesManager prefs;
  final AppTheme theme;
  final VoidCallback onToggleTheme;
  final ValueChanged<Locale> onLocaleChanged;
  final Locale? currentLocale;

  const MinesweeperScreen({
    super.key,
    required this.prefs,
    required this.theme,
    required this.onToggleTheme,
    required this.onLocaleChanged,
    required this.currentLocale,
  });

  @override
  State<MinesweeperScreen> createState() => _MinesweeperScreenState();
}

class _MinesweeperScreenState extends State<MinesweeperScreen> {
  late GameEngine _engine;
  late AudioController _audio;
  late HapticController _haptic;
  late TransformationController _transformController;

  bool _isVirtualTutorialActive = false;
  bool _lossRecordedForCurrentGame = false;

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();

    _audio = AudioController(enabled: widget.prefs.soundEnabled);
    _haptic = HapticController(enabled: widget.prefs.vibrationEnabled);

    final savedDiff = widget.prefs.difficulty;
    _engine = GameEngine(difficulty: savedDiff);

    _attachEngineCallbacks();

    // First run virtual tutorial check
    if (!widget.prefs.hasSeenTutorial) {
      _isVirtualTutorialActive = true;
    }
  }

  void _attachEngineCallbacks() {
    _engine.onStateChanged = () {
      if (mounted) setState(() {});
    };

    _engine.onCascadeReveal = (pt, count) {
      if (count > 2) {
        _audio.playCascade();
      } else {
        _audio.playClick();
      }
      _haptic.lightImpact();
    };

    _engine.onFlagPlaced = () {
      _audio.playFlag();
      _haptic.mediumImpact();
    };

    _engine.onFlagRemoved = () {
      _audio.playUnflag();
      _haptic.lightImpact();
    };

    _engine.onDetonate = () async {
      _audio.playExplode();
      _haptic.heavyImpact();

      if (!_lossRecordedForCurrentGame) {
        _lossRecordedForCurrentGame = true;
        await widget.prefs.recordGameResult(
          diff: _engine.difficulty,
          isWon: false,
        );
      }
    };

    _engine.onHintShown = () {
      _audio.playHint();
      _haptic.selectionClick();
    };

    _engine.onVictory = () async {
      _audio.playWin();
      _haptic.victoryPattern();

      final currentBest =
          widget.prefs.getStats(_engine.difficulty).bestTimeSeconds;
      final isNewBest = currentBest == null ||
          _engine.elapsedTimeSeconds < currentBest;

      await widget.prefs.recordGameResult(
        diff: _engine.difficulty,
        isWon: true,
        timeSeconds: _engine.elapsedTimeSeconds,
        wasAlreadyCounted: _lossRecordedForCurrentGame,
      );
      _lossRecordedForCurrentGame = false;

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => VictoryDialog(
            theme: widget.theme,
            timeSeconds: _engine.elapsedTimeSeconds,
            isNewBest: isNewBest,
            onPlayAgain: () {
              Navigator.of(ctx).pop();
              _restartGame();
            },
            onClose: () => Navigator.of(ctx).pop(),
          ),
        );
      }
    };
  }

  void _restartGame() {
    _lossRecordedForCurrentGame = false;
    _transformController.value = Matrix4.identity();
    _engine.restart();
    _haptic.selectionClick();
  }

  void _changeDifficulty(Difficulty diff) {
    if (_engine.difficulty == diff) return;
    _lossRecordedForCurrentGame = false;
    _transformController.value = Matrix4.identity();
    widget.prefs.setDifficulty(diff);
    _engine.setDifficulty(diff);
    _haptic.selectionClick();
  }

  void _toggleFlagMode() {
    setState(() {
      _engine.isFlagMode = !_engine.isFlagMode;
    });
    _haptic.selectionClick();
  }

  void _toggleSound() {
    final next = !_audio.enabled;
    setState(() {
      _audio.enabled = next;
    });
    widget.prefs.setSoundEnabled(next);
    _haptic.selectionClick();
  }

  void _toggleVibration() {
    final next = !_haptic.enabled;
    setState(() {
      _haptic.enabled = next;
    });
    widget.prefs.setVibrationEnabled(next);
    _haptic.selectionClick();
  }

  void _openStatsDialog() {
    _haptic.selectionClick();
    showDialog(
      context: context,
      builder: (ctx) => StatsDialog(
        theme: widget.theme,
        prefs: widget.prefs,
      ),
    );
  }

  void _startVirtualTutorial() {
    _haptic.selectionClick();
    setState(() {
      _isVirtualTutorialActive = true;
    });
  }

  void _exitVirtualTutorial() {
    _haptic.selectionClick();
    setState(() {
      _isVirtualTutorialActive = false;
    });
    widget.prefs.setTutorialSeen(true);
  }

  void _openLanguageDialog() {
    _haptic.selectionClick();
    final activeLocale =
        widget.currentLocale ?? Localizations.localeOf(context);
    showDialog(
      context: context,
      builder: (ctx) => LanguageDialog(
        theme: widget.theme,
        currentLocale: activeLocale,
        onSelectLocale: (loc) {
          _haptic.selectionClick();
          widget.onLocaleChanged(loc);
        },
      ),
    );
  }

  @override
  void dispose() {
    _engine.dispose();
    _audio.dispose();
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      body: Stack(
        children: [
          // Main Board & Header Layout
          Column(
            children: [
              // No-Text Symbol Header Bar
              HeaderBar(
                theme: theme,
                elapsedTimeSeconds: _engine.elapsedTimeSeconds,
                flagsRemaining: _engine.flagsRemaining,
                difficulty: _engine.difficulty,
                isFlagMode: _engine.isFlagMode,
                canUndo: _engine.canUndo,
                hasActiveHint: _engine.currentHint != null,
                soundEnabled: _audio.enabled,
                vibrationEnabled: _haptic.enabled,
                onRestart: _restartGame,
                onToggleFlagMode: _toggleFlagMode,
                onUndo: () {
                  _engine.undo();
                  _haptic.selectionClick();
                },
                onHint: () {
                  _engine.triggerHint();
                },
                onToggleSound: _toggleSound,
                onToggleVibration: _toggleVibration,
                onToggleTheme: widget.onToggleTheme,
                onSelectDifficulty: _changeDifficulty,
                onOpenStats: _openStatsDialog,
                onOpenHelp: _startVirtualTutorial,
                onOpenLanguage: _openLanguageDialog,
              ),

              // Interactive Minesweeper Board
              Expanded(
                child: BoardView(
                  grid: _engine.grid,
                  theme: theme,
                  isFlagMode: _engine.isFlagMode,
                  transformationController: _transformController,
                  onCellTap: (r, c) {
                    _engine.handleCellTap(r, c);
                  },
                  onCellLongPress: (r, c) {
                    _engine.handleCellLongPress(r, c);
                  },
                ),
              ),
            ],
          ),

          // Fully Interactive Virtual Board Tutorial Overlay
          if (_isVirtualTutorialActive)
            Positioned.fill(
              child: VirtualTutorialView(
                theme: theme,
                audio: _audio,
                haptic: _haptic,
                onExit: _exitVirtualTutorial,
              ),
            ),
        ],
      ),
    );
  }
}
