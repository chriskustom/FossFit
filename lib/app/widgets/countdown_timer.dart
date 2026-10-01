import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

class CountdownTimer extends StatefulWidget {
  const CountdownTimer({super.key});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigRepository>();

    final enabled = config.isEnabled(.timers, 'enabled');

    if (!enabled) {
      return const SizedBox.shrink();
    }

    final controller = context.read<CountdownTimerController>();

    controller.updateSettings(
      soundEnabled: config.isEnabled(.timers, 'enable_sound'),
      vibrate: config.isEnabled(.timers, 'vibrate'),
      sound: config.getSetting(.timers, 'alarm_sound'),
    );

    return Consumer<CountdownTimerController>(
      builder: (context, timer, _) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -3)),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const Divider(height: 1),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton.outlined(
                        onPressed: timer.reset,
                        icon: const Icon(Icons.restart_alt_rounded),
                        visualDensity: const VisualDensity(horizontal: 4, vertical: 0),
                      ),

                      Expanded(
                        child: Center(
                          child: InkWell(
                            onTap: timer.isRunning
                                ? timer.pause
                                : timer.remainingSeconds < timer.durationSeconds
                                ? timer.start
                                : () => _selectDuration(context, timer),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                _formatTime(timer.remainingSeconds),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      IconButton.filledTonal(
                        visualDensity: const VisualDensity(horizontal: 4, vertical: 0),
                        onPressed: timer.isRunning ? timer.pause : timer.start,
                        icon: Icon(timer.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _selectDuration(BuildContext context, CountdownTimerController timer) async {
    if (timer.isRunning) {
      return;
    }

    final selectedMinutes = timer.durationSeconds ~/ 60;

    final selectedSeconds = timer.durationSeconds % 60;

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return _DurationPickerDialog(initialMinutes: selectedMinutes, initialSeconds: selectedSeconds);
      },
    );

    if (result == null) {
      return;
    }

    await timer.setDuration(result);
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class _DurationPickerDialog extends StatefulWidget {
  final int initialMinutes;
  final int initialSeconds;

  const _DurationPickerDialog({required this.initialMinutes, required this.initialSeconds});

  @override
  State<_DurationPickerDialog> createState() => _DurationPickerDialogState();
}

class _DurationPickerDialogState extends State<_DurationPickerDialog> {
  late int _minutes;
  late int _seconds;

  @override
  void initState() {
    super.initState();

    _minutes = widget.initialMinutes;
    _seconds = widget.initialSeconds;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set timer duration'),

      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Minutes
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Minutes'),

              const SizedBox(height: 8),

              DropdownButton<int>(
                value: _minutes,
                items: List.generate(
                  61,
                  (index) => DropdownMenuItem(value: index, child: Text(index.toString().padLeft(2, '0'))),
                ),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _minutes = value;
                  });
                },
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),

          // Seconds
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Seconds'),

              const SizedBox(height: 8),

              DropdownButton<int>(
                value: _seconds,
                items: List.generate(
                  60,
                  (index) => DropdownMenuItem(value: index, child: Text(index.toString().padLeft(2, '0'))),
                ),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _seconds = value;
                  });
                },
              ),
            ],
          ),
        ],
      ),

      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),

        FilledButton(
          onPressed: () {
            final totalSeconds = (_minutes * 60) + _seconds;

            if (totalSeconds <= 0) return;

            Navigator.pop(context, totalSeconds);
          },
          child: const Text('Set'),
        ),
      ],
    );
  }
}

class CountdownTimerController extends ChangeNotifier {
  static const String prefsKey = 'timer_duration';
  static const int defaultDurationSeconds = 120;

  Timer? _timer;
  AudioPlayer? _audioPlayer;

  int _durationSeconds = defaultDurationSeconds;
  int _remainingSeconds = defaultDurationSeconds;
  bool _isRunning = false;

  String? _sound;
  bool _soundEnabled = false;
  bool _vibrate = false;

  bool _initialized = false;

  int get durationSeconds => _durationSeconds;
  int get remainingSeconds => _remainingSeconds;
  bool get isRunning => _isRunning;
  bool get isInitialized => _initialized;

  String? get sound => _sound;
  bool get soundEnabled => _soundEnabled;
  bool get vibrate => _vibrate;

  CountdownTimerController() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _durationSeconds = prefs.getInt(prefsKey) ?? defaultDurationSeconds;

      _remainingSeconds = _durationSeconds;
      _initialized = true;

      notifyListeners();
    } catch (_) {
      _initialized = true;
      notifyListeners();
    }
  }

  void updateSettings({required bool soundEnabled, required bool vibrate, String? sound}) {
    _soundEnabled = soundEnabled;
    _vibrate = vibrate;
    _sound = sound;
  }

  void start() {
    if (_isRunning || _remainingSeconds <= 0) {
      return;
    }

    _isRunning = true;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_remainingSeconds <= 1) {
      _remainingSeconds = 0;
      _isRunning = false;

      _timer?.cancel();
      _timer = null;

      notifyListeners();

      _timerFinished();
      return;
    }

    _remainingSeconds--;
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _timer = null;

    _isRunning = false;
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _timer = null;

    _remainingSeconds = _durationSeconds;
    _isRunning = false;

    notifyListeners();
  }

  Future<void> setDuration(int seconds) async {
    if (_isRunning) {
      return;
    }

    _durationSeconds = seconds;
    _remainingSeconds = seconds;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(prefsKey, seconds);
    } catch (_) {}

    notifyListeners();
  }

  Future<void> _timerFinished() async {
    // Vibrate
    if (_vibrate) {
      try {
        final hasVibrator = await Vibration.hasVibrator();

        if (hasVibrator) {
          await Vibration.vibrate(pattern: [0, 500, 200, 500]);
        }
      } catch (_) {}
    }

    // Play sound
    if (_soundEnabled) {
      try {
        _audioPlayer ??= AudioPlayer();

        if (_sound != null && _sound!.isNotEmpty) {
          await _audioPlayer!.play(DeviceFileSource(_sound!));
        } else {
          await _audioPlayer!.play(AssetSource('sounds/timer_complete.mp3'));
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;

    _audioPlayer?.dispose();
    _audioPlayer = null;

    super.dispose();
  }
}
