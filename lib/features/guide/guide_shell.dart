import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../core/app_config.dart';
import 'guide_dashboard_screen.dart';
import 'guide_profile_screen.dart';
import 'guide_activity_screen.dart';

class GuideShell extends StatefulWidget {
  const GuideShell({super.key});
  @override
  State<GuideShell> createState() => _GuideShellState();
}

class _GuideShellState extends State<GuideShell> {
  int _index = 0;

  final _pages = const [
    GuideDashboardScreen(),
    GuideActivityScreen(),
    GuideProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(key: ValueKey(_index), child: _pages[_index]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.task_alt_outlined), selectedIcon: Icon(Icons.task_alt_rounded), label: 'Help'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Guide'),
        ],
      ),
    );
  }
}
