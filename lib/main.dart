// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homecare_mobile/core/router/app_router.dart';
import 'package:homecare_mobile/core/utils/injections.dart';
import 'package:homecare_mobile/core/utils/logger.dart';
import 'package:homecare_mobile/features/auth/presentation/bloc/auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initInjections();

  logger.i('App started');
  runApp(const MyApp());
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
      ),
    );
  }
}
