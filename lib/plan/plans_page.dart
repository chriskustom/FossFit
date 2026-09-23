import 'package:flutter/material.dart';
import 'package:fossfit/animated_fab.dart';
import 'package:fossfit/app_search.dart';
import 'package:fossfit/db/repositories/plan_exercises_repository.dart';
import 'package:fossfit/db/repositories/plans_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/models/plan_model.dart';
import 'package:fossfit/plan/edit_plan_page.dart';
import 'package:fossfit/plan/plans_list.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class PlansPage extends StatefulWidget {
  final TabController tabController;

  const PlansPage({super.key, required this.tabController});

  @override
  State<PlansPage> createState() => PlansPageState();
}

class PlansPageState extends State<PlansPage>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return NavigatorPopHandler(
      onPopWithResult: (result) {
        if (navKey.currentState!.canPop() == false) return;
        final settings = context.watch<SettingsRepository>();
        final index =
            settings.getSetting(key: 'tabs').split(',').indexOf('PlansPage');
        if (widget.tabController.index == index) navKey.currentState!.pop();
      },
      child: Navigator(
        key: navKey,
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => _PlansPageWidget(
            navKey: navKey,
          ),
          settings: settings,
        ),
      ),
    );
  }
}

class _PlansPageWidget extends StatefulWidget {
  final GlobalKey<NavigatorState> navKey;

  const _PlansPageWidget({required this.navKey});

  @override
  createState() => _PlansPageWidgetState();
}

class _PlansPageWidgetState extends State<_PlansPageWidget> {
  String search = '';
  late List<Plan> plans;

  final Set<int> selected = {};
  final scroll = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _filterPlans() async {
    final allPlans = plans;
    List<Plan> tempFiltered = [];

    for (final plan in allPlans) {
      bool matches = plan.days.toLowerCase().contains(search.toLowerCase());
      if (!matches && search.isNotEmpty) {
        final planExercises = plan.exercises
            ?.where(
              (tbl) =>
                  tbl.planId == plan.id && tbl.exercise!.name.contains(search),
            )
            .toList();
        matches = (planExercises ?? []).isNotEmpty;
      }
      if (matches) {
        tempFiltered.add(plan);
      }
    }

    setState(() {
      plans = tempFiltered;
    });
  }

  @override
  Widget build(BuildContext context) {
    var planRepo =
        context.watch<PlansRepository>(); // Watch for changes to rebuild
    var planExRepo = context
        .watch<PlanExercisesRepository>(); // Watch for changes to rebuild
    plans = planRepo.plans;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          AppSearch(
            onShare: () async {
              final plans = (this.plans)
                  .where(
                    (plan) => selected.contains(plan.id),
                  )
                  .toList();

              final summaries = await Future.wait(
                plans.map((plan) async {
                  final days = plan.days.split(',').join(', ');
                  final exercises = plan.exercises
                      ?.where((pe) => pe.enabled)
                      .map((pe) => "- ${pe.exercise!.name}")
                      .join('\n');

                  return "$days:\n$exercises";
                }),
              );

              await SharePlus.instance
                  .share(ShareParams(text: summaries.join('\n\n')));
              setState(() {
                selected.clear();
              });
            },
            onChange: (value) {
              setState(() {
                search = value;
                _filterPlans(); // Re-filter when search changes
              });
            },
            onClear: () => setState(() {
              selected.clear();
            }),
            onDelete: () async {
              final copy = selected.toList();
              setState(() {
                selected.clear();
              });
              await planRepo.deletePlansByIds(copy);
              await planExRepo.deleteAllExercisesForPlansByIds(copy);
              planRepo.updatePlans(null);
            },
            onSelect: () => setState(() {
              selected.addAll(plans.map((plan) => plan.id!));
            }),
            selected: selected,
            onEdit: () async {
              final plan = plans.firstWhere(
                (element) => element.id == selected.first,
              );
              if (context.mounted)
                return Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditPlanPage(
                      plan: plan,
                    ),
                  ),
                );
            },
          ),
          Expanded(
            child: PlansList(
              scroll: scroll,
              plans: plans,
              navKey: widget.navKey,
              selected: selected,
              search: search,
              onSelect: (id) {
                if (selected.contains(id))
                  setState(() {
                    selected.remove(id);
                  });
                else
                  setState(() {
                    selected.add(id);
                  });
              },
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedFab(
        onPressed: () async {
          var plan = Plan(
            days: '',
            title: '',
          );
          if (context.mounted)
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditPlanPage(
                  plan: plan,
                ),
              ),
            );
        },
        label: Text('Add'),
        icon: Icon(Icons.add),
        scroll: scroll,
      ),
    );
  }
}
