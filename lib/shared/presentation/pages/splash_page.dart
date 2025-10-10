import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:homecare_mobile/core/router/app_router.dart';
import 'package:homecare_mobile/features/auth/presentation/bloc/auth_bloc.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _authBlocListener,
      child: const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }

  void _authBlocListener(BuildContext context, AuthState state) {
    if (state is AuthAuthenticated) {
      context.go(AppRouter.home);
    } else if (state is AuthUnauthenticated) {
      context.go(AppRouter.login);
    } else if (state is AuthError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.message)));
      context.go(AppRouter.login);
    }
  }
}
