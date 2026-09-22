import 'package:flutter/material.dart';
import 'package:fossfit/db/repositories/gym_sets_repository.dart';
import 'package:fossfit/db/repositories/settings_repository.dart';
import 'package:fossfit/models/gym_sets_model.dart';
import 'package:fossfit/sets/history_list.dart';
import 'package:provider/provider.dart';

class GraphHistoryPage extends StatefulWidget {
  final String name;
  final List<GymSets> gymSets;
  final bool? peek;

  const GraphHistoryPage({
    super.key,
    required this.name,
    required this.gymSets,
    this.peek = false,
  });

  @override
  createState() => _GraphHistoryPageState();
}

class _GraphHistoryPageState extends State<GraphHistoryPage> {
  late List<GymSets> sets = widget.gymSets;
  int limit = 20;
  final scroll = ScrollController();
  TabController? ctrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: Builder(
        builder: (context) {
          if (sets.isEmpty)
            return ListTile(
              title: Text("No data yet for ${widget.name}"),
              subtitle: const Text("Enter some data to view graphs here"),
            );

          return HistoryList(
            scroll: scroll,
            sets: sets,
            onSelect: (_) {},
            selected: const {},
            onNext: () {
              setState(() {
                limit += 10;
              });
              setSets();
            },
            peek: widget.peek,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    ctrl?.removeListener(tabListener);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        ctrl = DefaultTabController.of(context);
        ctrl?.addListener(tabListener);
      } catch (_) {/* ignored */}
    });
  }

  void setSets() async {
    final result = context
        .watch<GymSetsRepository>()
        .gymsets
        .where(
          (e) => !e.hidden && e.name == widget.name,
        )
        .take(limit)
        .toList();
    result.sort(
      (a, b) => a.created.compareTo(b.created),
    );
    setState(() {
      sets = result;
    });
  }

  void tabListener() {
    final settings = context.watch<SettingsRepository>();
    final index = settings.getSetting(key: 'tabs').split(',').indexOf('GraphsPage');
    if (ctrl!.indexIsChanging == true) return;
    if (ctrl!.index != index) return;
    setSets();
  }
}
