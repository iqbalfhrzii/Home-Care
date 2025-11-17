import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_nav_bar/google_nav_bar.dart'; // <-- 1. Import GNav
import 'package:homecare_mobile/core/router/app_router.dart';

// --- Definisi Warna (Penting untuk style) ---
const Color kPrimaryColor = Color(0xFF002F67);
const Color kUnselectedColor = Color(0xFF3F51B5);
const Color kWhiteColor = Colors.white;

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
    AppRouter.patients,
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
    // Logika GoRouter Anda untuk sinkronisasi UI, sudah benar
    final currentLocation = GoRouterState.of(context).matchedLocation;
    if (currentLocation.startsWith(AppRouter.home)) {
      _currentIndex = 0;
    } else if (currentLocation.startsWith(AppRouter.schedules)) {
      _currentIndex = 1;
    } else if (currentLocation.startsWith(AppRouter.patients)) {
      _currentIndex = 2;
    } else if (currentLocation.startsWith(AppRouter.reports)) {
      _currentIndex = 3;
    }

    return Scaffold(
      body: widget.child,
      // --- 2. Ganti BottomNavigationBar dengan GNav ---
      bottomNavigationBar: Container(
        // Tambahkan shadow dan background putih agar terlihat modern
        decoration: BoxDecoration(
          color: kWhiteColor,
          boxShadow: [
            BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(.1)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: kUnselectedColor.withOpacity(0.2),
              hoverColor: kUnselectedColor.withOpacity(0.1),
              gap: 8, // Spasi antara ikon dan teks
              activeColor:
                  kWhiteColor, // Warna ikon & teks aktif (di dalam pill)
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: kPrimaryColor, // Warna background pill
              color: kUnselectedColor, // Warna ikon & teks non-aktif
              tabs: const [
                GButton(icon: Icons.home_outlined, text: 'Home'),
                GButton(icon: Icons.calendar_month_outlined, text: 'Schedules'),
                GButton(icon: Icons.people_outline, text: 'Patients'),
                GButton(icon: Icons.insert_chart_outlined, text: 'Reports'),
              ],
              selectedIndex: _currentIndex,
              onTabChange: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}
