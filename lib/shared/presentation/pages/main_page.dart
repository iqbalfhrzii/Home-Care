import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:homecare_mobile/core/router/app_router.dart';

class MainPage extends StatefulWidget {
  final Widget child;

  const MainPage({super.key, required this.child});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  // WARNING: Order must match route paths exactly
  static const _routes = [
    AppRouter.home,
    AppRouter.schedules,
    AppRouter.reports,
  ];

  void _onItemTapped(int index) {
    if (index != _currentIndex) {
      context.go(_routes[index]);
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    if (currentLocation.startsWith(AppRouter.home)) {
      _currentIndex = 0;
    } else if (currentLocation.startsWith(AppRouter.schedules)) {
      _currentIndex = 1;
    } else if (currentLocation.startsWith(AppRouter.reports)) {
      _currentIndex = 2;
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(label: 'Home', icon: Icon(Icons.home)),
          BottomNavigationBarItem(
            label: 'Schedules',
            icon: Icon(Icons.calendar_month),
          ),
          BottomNavigationBarItem(
            label: 'Reports',
            icon: Icon(Icons.insert_chart),
          ),
        ],
      ),
    );
  }
}
