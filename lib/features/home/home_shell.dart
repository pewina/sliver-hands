import 'package:flutter/material.dart';

import '../../shared/widgets/app_bottom_navigation.dart';
import '../business/business_screen.dart';
import '../create/create_screen.dart';
import '../discover/discover_screen.dart';
import '../matches/matches_screen.dart';
import '../profile/profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _pages = const [
    DiscoverScreen(),
    BusinessScreen(),
    ProductContentScreen(),
    MatchesScreen(),
    ProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    body: AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(.02, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(_index), child: _pages[_index]),
    ),
    bottomNavigationBar: AppBottomNavigationBar(
      index: _index,
      onTap: (value) => setState(() => _index = value),
    ),
  );
}
