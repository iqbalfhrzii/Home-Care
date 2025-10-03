// lib/pages/home_page.dart

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // static const List<Widget> _widgetOptions = <Widget>[
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout', // Teks yang muncul saat ikon ditekan lama
            onPressed: () {
              // Navigasi kembali ke halaman login
              // 'popAndPushNamed' akan menghapus semua halaman sebelumnya dari stack
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/', // Rute untuk login_page.dart
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
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
