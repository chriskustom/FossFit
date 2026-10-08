import 'package:flutter/material.dart';
import 'package:fossfit/app/utils/constants.dart';
import 'package:fossfit/db/repositories/config_reposity.dart';
import 'package:provider/provider.dart';

class KustomNavBar extends StatelessWidget {
  final Function(NavRoute, NavRoute) onTap;
  const KustomNavBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Selector<ConfigRepository, (bool, String)>(
      selector: (_, config) => (config.isEnabled(.tabs, 'minimal_dock'), config.getSetting(.tabs, 'tabs')),
      builder: (context, options, _) {
        final (miniDock, tabs) = options;
        final routes = tabs.split(',').map((page) => NavRoute.values.byName(page.toLowerCase())).toList();

        final currentRoute = ModalRoute.of(context)?.settings.name;
        final selectedIndex = routes.indexWhere((page) => page == NavRoute.fromRoute(currentRoute));
        return miniDock
            ? Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                child: Center(
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(routes.length, (index) {
                          final tab = routes[index];
                          final isSelected = index == selectedIndex;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => onTap(tab, routes.first),
                              borderRadius: BorderRadius.circular(24),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                curve: Curves.easeOutCubic,
                                height: 48,
                                padding: EdgeInsets.symmetric(horizontal: isSelected ? 16 : 12),
                                decoration: BoxDecoration(
                                  color: isSelected ? color.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(tab.icon, color: isSelected ? color.onPrimary : color.onSurface, size: 24),
                                    AnimatedSize(
                                      duration: const Duration(milliseconds: 350),
                                      curve: Curves.easeOutCubic,
                                      child: isSelected
                                          ? Padding(
                                              padding: const EdgeInsets.only(left: 8),
                                              child: Text(
                                                tab.label,
                                                maxLines: 1,
                                                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color.onPrimary),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              )
            : NavigationBar(
                height: 60,
                backgroundColor: color.surface,
                selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
                onDestinationSelected: (index) => onTap(routes[index], routes.first),
                destinations: routes.map((page) {
                  return NavigationDestination(icon: Icon(page.icon), label: page.label);
                }).toList(),
              );
      },
    );
  }
}
