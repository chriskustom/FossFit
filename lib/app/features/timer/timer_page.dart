import 'package:flutter/material.dart';
import 'package:fossfit/app/features/timer/timer_progress_widgets.dart';
import 'package:fossfit/app/features/timer/timer_state.dart';
import 'package:fossfit/app/settings/settings_page.dart';
import 'package:fossfit/app/widgets/fanimated_fab.dart';
import 'package:provider/provider.dart';

class TimerPage extends StatefulWidget {
  final int? total;
  final int? progress;

  const TimerPage({super.key, this.total, this.progress});

  @override
  createState() => TimerPageState();
}

class TimerPageState extends State<TimerPage> {
  TimerState timerState = TimerState();
  int? total;
  int? progress;

  @override
  Widget build(BuildContext context) {
    timerState = context.watch<TimerState>();
    if (total != null && progress != null) {
      timerState.setTimer(total!, progress!);
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: const Center(child: TimerCircularProgressIndicator()),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: timerState.timer.isRunning() ? AnimatedFab(onPressed: () async => await timerState.stopTimer(), icon: const Icon(Icons.stop), label: const Text("Stop")) : const SizedBox(),
      ),
    );
  }
}
