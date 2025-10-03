// lib/main.dart
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:homecare_mobile/core/utils/injections.dart';
import 'package:homecare_mobile/core/utils/logger.dart';
import 'package:homecare_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:homecare_mobile/main.gr.dart';

class AuthGuard extends AutoRouteGuard {
  AuthGuard(this._isAuthenticated);

  final bool Function() _isAuthenticated;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    final isAuth = _isAuthenticated();
    logger.i(
      'AuthGuard: checking navigation to ${resolver.route.name}. Is authenticated: $isAuth',
    );

    if (isAuth) {
      logger.i(
        'AuthGuard: User is authenticated. Proceeding to ${resolver.route.name}',
      );
      resolver.next(true);
    } else {
      logger.i(
        'AuthGuard: User is NOT authenticated. Redirecting to LoginRoute.',
      );
      // Use redirect instead of push for cleaner navigation
      resolver.redirectUntil(const LoginRoute());
    }
  }
}

@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')
class AppRouter extends RootStackRouter {
  AppRouter() : super() {
    logger.d('AppRouter: Initializing AuthGuard.');
    authGuard = AuthGuard(() {
      final isAuthenticated = sl<AuthBloc>().state is AuthAuthenticated;
      logger.t(
        'AuthGuard check: AuthBloc state is ${sl<AuthBloc>().state.runtimeType}. Authenticated: $isAuthenticated',
      );
      return isAuthenticated;
    });
    logger.d('AppRouter: AuthGuard initialized.');
  }

  late final AuthGuard authGuard;

  @override
  RouteType get defaultRouteType => const RouteType.material();

  @override
  List<AutoRoute> get routes {
    logger.d('AppRouter: Defining routes.');
    return [
      AutoRoute(page: SplashRoute.page, initial: true),
      AutoRoute(
        page: MainRoute.page,
        guards: [authGuard],
        children: [
          AutoRoute(page: HomeRoute.page),
          AutoRoute(page: ReportRoute.page),
          AutoRoute(page: ScheduleRoute.page),
        ],
      ),
      AutoRoute(page: LoginRoute.page),
    ];
  }

  @override
  List<AutoRouteGuard> get guards => [];
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  logger.i('Main: Widgets binding initialized.');

  await initInjections();
  logger.i('Main: Dependency injections initialized.');

  // REMOVED: sl<AuthBloc>().add(const AuthCheckRequested());
  // Let SplashPage handle the auth check

  logger.i('App initialized, running MyApp');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key}) {
    logger.d('MyApp constructor called');
  }

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    logger.d('Building MyApp widget');

    return MaterialApp.router(
      title: 'Aplikasi Percobaan',
      theme: ThemeData(primarySwatch: Colors.blue),
      routerConfig: _appRouter.config(),
    );
  }
}
