import 'package:flutter/material.dart';
import 'package:fossfit/app/services/features/exercise_services.dart';
import 'package:fossfit/app/services/features/plan_services.dart';
import 'package:fossfit/app/shell/app_shell.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/widgets/fanimated_fab.dart';
import 'package:fossfit/db/models/features/plan_model.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:fossfit/db/repositories/plan_repository.dart';
import 'package:provider/provider.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<StatefulWidget> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  late ConfigRepository config;
  List<Plan>? _displayPlans;

  final ScrollController scroll = ScrollController();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    config = context.watch<ConfigRepository>();
    var repo = context.watch<PlansRepository>();

    final plans = _displayPlans ?? repo.plans;
    return AppShell(
      title: 'Plans',
      body: _buildBody(plans),
      floatingActionButton: AnimatedFab(
        onPressed: () async {
          //TODO Create new plan
        },
        label: const Text('Add'),
        icon: const Icon(Icons.add),
        scroll: scroll,
      ),
    );
  }

  Widget _buildBody(List<Plan> plans) {
    final weekday = weekdays[DateTime.now().weekday - 1];
    final exerciseServices = ExerciseServices(context: context);

    if (plans.isEmpty) return _nonFound();
    return ReorderableListView.builder(
      scrollController: scroll,
      itemCount: plans.length,
      padding: const EdgeInsets.only(bottom: 96, top: 16),
      itemBuilder: (context, index) {
        final plan = plans[index];
        Widget title = const Text("Daily");
        if (plan.name.isNotEmpty == true) {
          final today = plan.days.split(',').contains(weekday);
          title = Text(
            plan.name,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: today ? FontWeight.bold : null, decoration: today ? TextDecoration.underline : null),
          );
        } else if (plan.days.split(',').length < 7) {
          title = RichText(text: TextSpan(children: _getDayListFormatted(plan.days, weekday)));
        }

        var exercises = exerciseServices.getExercisesByPlanId(plan.id!).map((e) => e.name).join(', ');
        return ListTile(
          key: Key(plan.id.toString()),
          leading: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.inversePrimary, borderRadius: BorderRadius.circular(12)),
              child: Center(
                child: Text(
                  plan.name.isNotEmpty == true ? plan.name[0] : plan.days[0].toUpperCase(),
                  textAlign: TextAlign.justify,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
          title: title,
          subtitle: Text(exercises, maxLines: 2, overflow: .ellipsis),
          trailing: ReorderableDragStartListener(index: index, child: const Icon(Icons.drag_handle)),
          onTap: () async {
            var services = PlanServices(context: context);
            await services.openPlanPage(context, plan.id!);
          },
        );
      },
      onReorderItem: (oldIndex, newIndex) {
        context.read<PlansRepository>().reorderPlans(oldIndex, newIndex);
      },
    );
  }

  Widget _nonFound() {
    return ListTile(
      title: const Text("No plans found"),
      subtitle: Text("Tap to create "),
      // onTap: () async { TODO make on serach
      //   final plan = Plan(
      //     days: '',
      //     name: '',
      //   );
      //   if (context.mounted)
      //     await Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //         builder: (context) => EditPlanPage(
      //           plan: plan,
      //         ),
      //       ),
      //     );
      // },
    );
  }

  List<InlineSpan> _getDayListFormatted(String days, String today) {
    final style = Theme.of(context).textTheme.bodyLarge;

    return days.split(',').expand((day) {
      final trimmedDay = day.trim();
      final isToday = trimmedDay == today;

      return [
        TextSpan(
          text: trimmedDay,
          style: style?.copyWith(fontWeight: isToday ? FontWeight.bold : null, decoration: isToday ? TextDecoration.underline : null),
        ),
        const TextSpan(text: ', '),
      ];
    }).toList()..removeLast();
  }
}
