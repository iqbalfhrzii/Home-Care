// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:homecare_mobile/core/router/app_router.dart';
import 'package:homecare_mobile/core/utils/injections.dart';
import 'package:homecare_mobile/core/utils/logger.dart';
import 'package:homecare_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initInjections();

  // Initialize locale data for DateFormat
  await initializeDateFormatting('id_ID', null);

  logger.i('App started');

  // Global error handlers to capture uncaught exceptions and report to console/logger
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    logger.e(
      'FlutterError',
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  runZonedGuarded(
    () {
      runApp(const MyApp());
    },
    (error, stack) {
      logger.e('UncaughtZoneError', error: error, stackTrace: stack);
      // Also print to console so `flutter run` / logcat captures it
      debugPrint('Uncaught error: $error');
      debugPrintStack(stackTrace: stack);
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(sl<AuthBloc>());
    logger.d('MyApp initialized with GoRouter');
  }

  @override
  Widget build(BuildContext context) {
    logger.d('Building MyApp widget');

    return BlocProvider<AuthBloc>.value(
      value: sl<AuthBloc>()..add(const AuthCheckRequested()),
      child: MaterialApp.router(
        title: 'Aplikasi Percobaan',
        theme: ThemeData(primarySwatch: Colors.blue),
        routerConfig: _appRouter.router,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('id', 'ID'), // Indonesian
          Locale('en', 'US'), // English
        ],
        locale: const Locale('id', 'ID'),
      ),
    );
  }
}
