import 'package:flutter/material.dart';

void main() {
  runApp(const AgendaRepApp());
}

class AgendaRepApp extends StatelessWidget {
  const AgendaRepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgendaRep',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text("Bem-vindo ao AgendaRep!"),
      ),
    );
  }
}
