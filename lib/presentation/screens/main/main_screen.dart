import 'package:flutter/material.dart';

import '../home/home_screen.dart';
import '../upcoming/upcoming_screen.dart';
import '../insights/insights_screen.dart';

/// Main shell screen with bottom navigation bar
/// Contains: Home, Upcoming, Insights tabs
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Keep screens alive to preserve state
  final List<Widget> _screens = const [
    HomeScreen(),
    UpcomingScreen(),
    InsightsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          backgroundColor: theme.scaffoldBackgroundColor,
          indicatorColor: theme.colorScheme.primary.withAlpha(30),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.work_outline),
              selectedIcon: Icon(Icons.work, color: theme.colorScheme.primary),
              label: 'Jobs',
            ),
            NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(
                Icons.calendar_month,
                color: theme.colorScheme.primary,
              ),
              label: 'Upcoming',
            ),
            NavigationDestination(
              icon: const Icon(Icons.insights_outlined),
              selectedIcon: Icon(
                Icons.insights,
                color: theme.colorScheme.primary,
              ),
              label: 'Insights',
            ),
          ],
        ),
      ),
    );
  }
}
