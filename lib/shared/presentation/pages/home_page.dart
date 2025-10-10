import 'package:flutter/material.dart';
import 'package:homecare_mobile/features/auth/presentation/widgets/logout_confirmation_dialog.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        centerTitle: true,
        actions: const [TopMenu()],
      ),
      body: const HomeView(),
    );
  }
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Halaman Beranda', style: TextStyle(fontSize: 24)),
    );
  }
}

class TopMenu extends StatefulWidget {
  const TopMenu({super.key});

  @override
  State<TopMenu> createState() => _TopMenuState();
}

class _TopMenuState extends State<TopMenu> {
  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'TopMenuButton');

  @override
  void dispose() {
    _buttonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      childFocusNode: _buttonFocusNode,
      menuChildren: [
        MenuItemButton(
          onPressed: () => showLogoutDialog(context),
          child: const Text('Logout'),
        ),
      ],
      builder: (_, MenuController controller, __) {
        return IconButton(
          focusNode: _buttonFocusNode,
          icon: const Icon(Icons.more_vert),
          tooltip: 'Menu lainnya',
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
        );
      },
    );
  }
}
