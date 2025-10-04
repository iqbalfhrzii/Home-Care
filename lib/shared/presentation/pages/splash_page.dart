import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homecare_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:homecare_mobile/main.gr.dart';

@RoutePage()
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});


  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: _authBlocListener,
      child: const Scaffold(
        backgroundColor: Color(0xFFE8EAF6),
        body: _SplashView(),
      ),
    );
  }

  void _authBlocListener(BuildContext context, AuthState state) {
    if (state is AuthAuthenticated) {
      context.router.replace(const MainRoute());
    } else if (state is AuthUnauthenticated) {
      context.router.replace(const LoginRoute());
    }
    // If AuthError, decide what to do (maybe show error, then go to login)
    if (state is AuthError) {
      context.router.replace(const LoginRoute());
    }
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/idHW0aFfe7_logos.png',
            width: 250,
            height: 100,
          ),
          const SizedBox(height: 20),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3F51B5)),
          ),
        ],
      ),
    );
  }
}
