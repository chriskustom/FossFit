import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

class CountdownTimer extends StatefulWidget {
  const CountdownTimer({super.key});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;

  final AudioPlayer _audioPlayer = AudioPlayer();

  String? sound;
  bool? soundEnabled;
  bool? vibrate;
  int? duration;
  late ConfigRepository config;
  int _durationSeconds = 120;
  int _remainingSeconds = 120;

  bool _isRunning = false;
  bool _configInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_configInitialized) {
      final config = context.read<ConfigRepository>();

      _durationSeconds = config.getInt(.timers, 'duration');
      _remainingSeconds = _durationSeconds;

      _configInitialized = true;
    }
  }

  @override
  void initState() {
    super.initState();

    _durationSeconds = config.getInt(.timers, 'duration');
    _remainingSeconds = _durationSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
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

    context.read<ConfigRepository>().setSetting(category: .timers, key: 'duration', value: result.toString());
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
    _durationSeconds = config.getInt(.timers, 'duration');
    return timer
        ? Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -3))],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const Divider(),
                  Row(
                    mainAxisSize: .min,
                    children: [
                      IconButton.outlined(onPressed: _resetTimer, icon: const Icon(Icons.restart_alt_rounded)),
                      const SizedBox(width: 50),
                      GestureDetector(
                        onTap: _selectDuration,
                        child: Column(
                          children: [
                            Text(
                              _formatTime(),
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, fontFeatures: [FontFeature.tabularFigures()]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 50),
                      IconButton.filledTonal(
                        onPressed: _isRunning ? _pauseTimer : _startTimer,
                        icon: Icon(_isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      ),
                    ],
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
                items: List.generate(61, (index) => DropdownMenuItem(value: index, child: Text(index.toString().padLeft(2, '0')))),
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
                items: List.generate(60, (index) => DropdownMenuItem(value: index, child: Text(index.toString().padLeft(2, '0')))),
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
