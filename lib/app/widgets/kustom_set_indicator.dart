import 'package:flutter/material.dart';
import 'package:fossfit/db/models/features/gymset_model.dart';

class KustomSetIndicator extends StatelessWidget {
  const KustomSetIndicator({super.key, required this.sets, required this.max, required this.full});

  final List<GymSet> sets;
  final int max;
  final bool full;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return full ? _full(theme) : _blips(theme);
  }

  Widget _full(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < max; i++) ...[
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (i < sets.length) ...[
                  SizedBox(
                    height: 16,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${(sets[i].reps.toInt())} × '
                        '${(sets[i].weight)}'
                        '${sets[i].unit}',
                        style: theme.textTheme.labelSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 4),

                SizedBox(
                  height: 6,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: theme.colorScheme.outlineVariant),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: AnimatedFractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: sets.length > i ? 1 : 0,
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.ease,
                        child: DecoratedBox(decoration: BoxDecoration(color: theme.colorScheme.primary)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (i < max - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }

  Widget _blips(ThemeData theme) {
    final items = <Widget>[];

    for (int i = 0; i < max; i++) {
      items.add(
        SizedBox(
          width: 10,
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: theme.colorScheme.outlineVariant),
            height: 4,
            child: AnimatedFractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: sets.length > i ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.ease,
              child: DecoratedBox(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: theme.colorScheme.primary),
              ),
            ),
          ),
        ),
      );

      if (i < max - 1) {
        items.add(const SizedBox(width: 6));
      }
    }
    return Row(children: [...items]);
  }
}
