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
  static const String prefsKey = 'timer_duration';
  Timer? _timer;

  final AudioPlayer _audioPlayer = AudioPlayer();

  String? sound;
  bool? soundEnabled;
  bool? vibrate;

  int _durationSeconds = 120;
  int _remainingSeconds = 120;

  bool _isRunning = false;

  late SharedPreferences prefs;
  @override
  void initState() {
    super.initState();

    _initializePrefs();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializePrefs() async {
    try {
      prefs = await SharedPreferences.getInstance();

      final savedDuration = prefs.getInt(prefsKey) ?? 120;

      if (!mounted) return;

      setState(() {
        _durationSeconds = savedDuration;
        _remainingSeconds = savedDuration;
      });
    } catch (_) {}
  }

  void _startTimer() {
    if (_isRunning || _remainingSeconds <= 0) return;

    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();

        setState(() {
          _remainingSeconds = 0;
          _isRunning = false;
        });

        _timerFinished();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();

    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();

    setState(() {
      _remainingSeconds = _durationSeconds;
      _isRunning = false;
    });
  }

  Future<void> _timerFinished() async {
    // Vibrate
    if (vibrate == true && await Vibration.hasVibrator()) {
      Vibration.vibrate(pattern: [0, 500, 200, 500]);
    }

    // Play sound
    if (soundEnabled == true) {
      if (sound != null) {
        await _audioPlayer.play(DeviceFileSource(sound!));
      } else {
        await _audioPlayer.play(AssetSource('sounds/timer_complete.mp3'));
      }
    }
  }

  String _formatTime() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDuration() async {
    if (_isRunning) return;

    int selectedMinutes = _durationSeconds ~/ 60;
    int selectedSeconds = _durationSeconds % 60;

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return _DurationPickerDialog(initialMinutes: selectedMinutes, initialSeconds: selectedSeconds);
      },
    );

    if (result == null || !mounted) return;

    prefs.setInt(prefsKey, result);
    setState(() {
      _durationSeconds = result;
      _remainingSeconds = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    var config = context.watch<ConfigRepository>();
    var timer = config.isEnabled(.timers, 'enabled');
    vibrate = config.isEnabled(.timers, 'vibrate');
    soundEnabled = config.isEnabled(.timers, 'enable_sound');
    sound = config.getSetting(.timers, 'alarm_sound');
    return timer
        ? Container(
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
                          onPressed: _resetTimer,
                          icon: const Icon(Icons.restart_alt_rounded),
                          visualDensity: .compact.copyWith(horizontal: 4),
                        ),

                        Expanded(
                          child: Center(
                            child: InkWell(
                              onTap: _isRunning
                                  ? _pauseTimer
                                  : _remainingSeconds < _durationSeconds
                                  ? _startTimer
                                  : _selectDuration,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                child: Text(
                                  _formatTime(),
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
                          visualDensity: .compact.copyWith(horizontal: 4),
                          onPressed: _isRunning ? _pauseTimer : _startTimer,
                          icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        : SizedBox.shrink();
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
