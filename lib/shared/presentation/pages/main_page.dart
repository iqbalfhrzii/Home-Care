import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:homecare_mobile/main.gr.dart';

@RoutePage()
class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoTabsScaffold(
      routes: const [HomeRoute(), ReportRoute(), ScheduleRoute()],
      bottomNavigationBuilder: _scaffoldBottomNavigationBuilder,
    );
  }

  Widget _scaffoldBottomNavigationBuilder(
    BuildContext context,
    TabsRouter tabsRouter,
  ) {
    return BottomNavigationBar(
      currentIndex: tabsRouter.activeIndex,
      onTap: tabsRouter.setActiveIndex,
      items: const [
        BottomNavigationBarItem(label: 'Users', icon: Icon(Icons.home)),
        BottomNavigationBarItem(label: 'Posts', icon: Icon(Icons.insert_chart)),
        BottomNavigationBarItem(
          label: 'Settings',
          icon: Icon(Icons.calendar_month),
        ),
      ],
    );
  }
}
