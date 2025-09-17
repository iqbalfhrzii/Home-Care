// lib/main.dart
import 'package:flutter/material.dart';
import 'package:testaa/core/service_locator/service_locator.dart';
import 'package:testaa/pages/login_page.dart';
import 'package:testaa/pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ServiceLocator.setup();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Percobaan',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}

