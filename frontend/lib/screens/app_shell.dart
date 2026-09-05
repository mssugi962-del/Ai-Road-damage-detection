import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'detection_screen.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'road_damage_map_screen.dart';

class AppShell extends StatefulWidget {
  static const routeName = '/home';

  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _selectedIndex = widget.initialIndex;
  int _homeRefreshKey = 0;
  int _mapRefreshKey = 0;
  int _historyRefreshKey = 0;

  void openTab(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) _homeRefreshKey++;
      if (index == 2) _mapRefreshKey++;
      if (index == 3) _historyRefreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(key: ValueKey('home_$_homeRefreshKey')),
      const DetectionScreen(),
      RoadDamageMapScreen(key: ValueKey('map_$_mapRefreshKey')),
      HistoryScreen(key: ValueKey('history_$_historyRefreshKey')),
    ];

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.04, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: AppShellNavigation(
          key: ValueKey(_selectedIndex),
          openTab: openTab,
          child: pages[_selectedIndex],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        onTap: openTab,
      ),
    );
  }
}

class AppShellNavigation extends InheritedWidget {
  final ValueChanged<int> openTab;

  const AppShellNavigation({
    super.key,
    required this.openTab,
    required super.child,
  });

  static AppShellNavigation of(BuildContext context) {
    final navigation = context
        .dependOnInheritedWidgetOfExactType<AppShellNavigation>();
    assert(navigation != null, 'AppShellNavigation was not found.');
    return navigation!;
  }

  @override
  bool updateShouldNotify(AppShellNavigation oldWidget) {
    return openTab != oldWidget.openTab;
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.dashboard_rounded, 'Home'),
      (Icons.document_scanner_outlined, 'Detect'),
      (Icons.map_outlined, 'Map'),
      (Icons.history_rounded, 'History'),
    ];

    return SafeArea(
      child: Container(
        height: 74,
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.navy,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            for (int index = 0; index < items.length; index++)
              Expanded(
                child: _BottomNavItem(
                  icon: items[index].$1,
                  label: items[index].$2,
                  selected: index == selectedIndex,
                  onTap: () => onTap(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accent.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? AppTheme.accent : Colors.white60),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
