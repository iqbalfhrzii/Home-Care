import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homecare_mobile/features/auth/presentation/bloc/auth_bloc.dart';

Future<void> showLogoutDialog(BuildContext context) async {
  final bool? logout = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const LogoutConfirmationDialog(),
  );

  if (logout == true && context.mounted) {
    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }
}

class LogoutConfirmationDialog extends StatelessWidget {
  const LogoutConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Keluar'),
      content: const Text('Apakah Anda yakin ingin logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Logout'),
        ),
      ],
    );
  }
}
