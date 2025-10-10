// import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:homecare_mobile/core/router/app_router.dart';
import 'package:homecare_mobile/features/auth/presentation/bloc/auth_bloc.dart';
// import 'package:homecare_mobile/main.gr.dart';

// @RoutePage()
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  const _EmailField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Email Address',
        hintText: 'Enter your email',
        prefixIcon: Icon(Icons.email),
        border: OutlineInputBorder(),
      ),
      validator: _validator,
    );
  }

  String? _validator(String? v) {
    if (v == null || v.trim().isEmpty || !v.contains('@')) {
      return 'Valid email required';
    }
    return null;
  }
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: BlocListener<AuthBloc, AuthState>(
        listener: _authBlocListener,
        child: _LoginView(
          formKey: _formKey,
          emailController: _email,
          passwordController: _password,
          obscure: _obscure,
          toggleObscure: () => setState(() => _obscure = !_obscure),
          onLogin: _login,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _authBlocListener(BuildContext context, AuthState state) {
    if (state is AuthError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.message)));
    }
    if (state is AuthAuthenticated) {
      context.go(AppRouter.home); // ← Update this line
    }
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AuthLoginRequested(
          email: _email.text.trim(),
          password: _password.text.trim(),
        ),
      );
    }
  }
}

class _LoginView extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscure;
  final VoidCallback toggleObscure;
  final VoidCallback onLogin;

  const _LoginView({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscure,
    required this.toggleObscure,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        spacing: 30,
        children: [
          const Spacer(),
          Image.asset(
            'assets/images/idHW0aFfe7_logos.png',
            width: 250,
            height: 100,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: formKey,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 16,
                  children: [
                    const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _EmailField(controller: emailController),
                    // const SizedBox(height: 0), // removed since height < 1
                    _PasswordField(
                      controller: passwordController,
                      obscure: obscure,
                      toggle: toggleObscure,
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (_, state) {
                        final loading = state is AuthLoading;
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3F51B5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: loading ? null : onLogin,
                            child: loading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Text(
                  '© 2024 Home Care System. All rights reserved.',
                  style: TextStyle(color: Colors.black54),
                ),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback toggle;
  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.toggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: 'Password',
        hintText: 'Enter your password',
        prefixIcon: const Icon(Icons.lock),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: toggle,
        ),
      ),
      validator: _validator,
    );
  }

  String? _validator(String? v) {
    if (v == null || v.length < 6) {
      return 'Minimum 6 characters';
    }

    return null;
  }
}
