// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homecare_mobile/core/router/app_router.dart';
import 'package:homecare_mobile/core/theme/theme.dart';
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
    // final brightness = View.of(context).platformDispatcher.platformBrightness;

    // Retrieves the default theme for the platform
    //TextTheme textTheme = Theme.of(context).textTheme;

    // Use with Google Fonts package to use downloadable fonts
    TextTheme textTheme = createTextTheme(context, "Roboto", "Montserrat");

    MaterialTheme theme = MaterialTheme(textTheme);

    logger.d('Building MyApp widget');

    return BlocProvider<AuthBloc>.value(
      value: sl<AuthBloc>()..add(const AuthCheckRequested()),
      child: MaterialApp.router(
        title: 'Aplikasi Percobaan',
        // theme: brightness == Brightness.light ? theme.light() : theme.dark(),
        theme: theme.light(),
        routerConfig: _appRouter.router,
      ),
    );
  }
}
