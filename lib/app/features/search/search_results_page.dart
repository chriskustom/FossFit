import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fossfit/app/services/app_services.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/app/utils/utils.dart';

class SearchResultsPage extends StatefulWidget {
  final List<dynamic> results;
  final void Function()? onItemTap;
  final String? initialFilter;

  const SearchResultsPage({super.key, required this.results, this.onItemTap, this.initialFilter});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final filters = ['notes', 'notebooks', 'lists', 'goals'];
  List<dynamic> displayList = [];
  Set<String> selectedFilters = {};

  @override
  void initState() {
    super.initState();
    displayList.clear();
    displayList = List.from(widget.results);
    if (widget.initialFilter != null && filters.contains(widget.initialFilter!.replaceAll('/', ''))) {
      filterByType(widget.initialFilter!.replaceAll('/', ''));
    }
  }

  @override
  void didUpdateWidget(covariant SearchResultsPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!listEquals(oldWidget.results, widget.results)) {
      setState(() {
        displayList = List.from(widget.results);
      });
    }
  }

  @override
  void dispose() {
    displayList.clear();
    super.dispose();
  }

  void resetFilter() {
    setState(() {
      displayList = List.from(widget.results);
    });
  }

  void filterByType(String filter) {
    setState(() {
      // if (selectedFilters.contains(filter)) {
      //   selectedFilters.remove(filter);
      // } else {
      //   selectedFilters.add(filter);
      // }

      // if (selectedFilters.isEmpty) {
      //   displayList = List.from(widget.results);
      // } else {
      //   displayList.clear();
      //   if (selectedFilters.contains('notes')) {
      //     displayList.addAll(widget.results.whereType<NoteFts>());
      //   }
      //   if (selectedFilters.contains('notebooks')) {
      //     displayList.addAll(widget.results.whereType<NotebookFts>());
      //   }
      //   if (selectedFilters.contains('lists')) {
      //     displayList.addAll(widget.results.whereType<ListFts>());
      //     displayList.addAll(widget.results.whereType<ListItemFts>());
      //   }
      //   if (selectedFilters.contains('lists')) {
      //     displayList.addAll(widget.results.whereType<GoalFts>());
      //     displayList.addAll(widget.results.whereType<TaskFts>());
      //   }
      //   displayList.addAll(widget.results.where((item) => item is EntityTag && item.entityType == filter));
      // }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, left: 8, top: 4),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((filter) {
                      final isSelected = selectedFilters.contains(filter);

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(filter.toTitleCase),
                          selected: isSelected,
                          onSelected: (_) => filterByType(filter),
                          selectedColor: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          labelStyle: theme.textTheme.labelSmall?.copyWith(
                            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              ElevatedButton(
                clipBehavior: Clip.hardEdge,
                onPressed: () {
                  setState(() {
                    selectedFilters.clear();
                    displayList = List.from(widget.results);
                  });
                },
                child: Icon(Icons.clear),
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(0),
            itemCount: displayList.length,
            itemBuilder: (context, index) {
              //final item = displayList[index];
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _getTile(String title, String subtitle, Icon icon, Function() onTap, {IconData? trailing}) {
    final myColor = Theme.of(context).colorScheme.onSecondaryContainer;
    return Card(
      elevation: globalElevation,

      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: AppHaptics.tapWithHaptics(context, onTap),
        child: Stack(
          children: [
            ListTile(
              title: Text(
                title,
                style: Theme.of(context).textTheme.labelMedium,
                textScaler: TextScaler.linear(0.9),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ListTileStyle.drawer,
              subtitle: subtitle.isEmpty ? null : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
              leading: icon,
              trailing: Icon(trailing, color: myColor),
            ),
          ],
        ),
      ),
    );
  }
}
