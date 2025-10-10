import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:homecare_mobile/core/utils/logger.dart';
import 'package:homecare_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:homecare_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:homecare_mobile/features/reports/report_list_page.dart';
import 'package:homecare_mobile/features/schedules/presentation/pages/schedule_list_page.dart';
import 'package:homecare_mobile/features/schedules/presentation/pages/schedule_page.dart';
import 'package:homecare_mobile/pages/home_page.dart';
import 'package:homecare_mobile/shared/presentation/pages/main_page.dart';
import 'package:homecare_mobile/shared/presentation/pages/splash_page.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String schedules = '/schedules';
  static const String reports = '/reports';

  final AuthBloc _authBloc;

  AppRouter(this._authBloc);

  late final GoRouter router = GoRouter(
    initialLocation: splash,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(_authBloc.stream),
    redirect: _handleRedirect,
    routes: [
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainPage(child: child);
        },
        routes: [
          GoRoute(
            path: home,
            name: 'home',
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const HomePage()),
          ),
          GoRoute(
            path: schedules,
            name: 'scheduleList',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ScheduleListPage(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                name: 'schedule',
                builder: (context, state) {
                  final id = int.parse(state.pathParameters['id']!);
                  return SchedulePage(id: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: reports,
            name: 'reports',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ReportListPage(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );

  String? _handleRedirect(BuildContext context, GoRouterState state) {
    final authState = _authBloc.state;
    final isOnSplash = state.matchedLocation == splash;
    final isOnLogin = state.matchedLocation == login;
    final isAuthenticated = authState is AuthAuthenticated;
    final isAuthenticating = authState is AuthLoading;

    logger.i('Router redirect check:');
    logger.i('  Current location: ${state.matchedLocation}');
    logger.i('  Auth state: ${authState.runtimeType}');
    logger.i('  Is authenticated: $isAuthenticated');

    // ⚠️ CRITICAL: Let splash page handle initial routing
    if (isOnSplash) {
      logger.i('  On splash, allowing through');
      return null;
    }

    // ⚠️ WARNING: Prevent redirect loops during auth check
    if (isAuthenticating) {
      logger.i('  Auth in progress, staying on current page');
      return null;
    }

    // If authenticated and trying to access login, redirect to home
    if (isAuthenticated && isOnLogin) {
      logger.i('  Authenticated user on login, redirecting to home');
      return home;
    }

    // If not authenticated and trying to access protected routes
    if (!isAuthenticated && !isOnLogin && !isOnSplash) {
      logger.i(
        '  Unauthenticated user on protected route, redirecting to login',
      );
      return login;
    }

    logger.i('  No redirect needed');
    return null;
  }
}

// Helper class to make GoRouter reactive to BLoC state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
