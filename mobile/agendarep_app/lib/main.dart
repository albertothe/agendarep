import 'package:flutter/material.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'settings_page.dart';

void main() {
  runApp(const AgendaRepApp());
}

class AgendaRepApp extends StatelessWidget {
  const AgendaRepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgendaRep',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      routes: {
        '/': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
