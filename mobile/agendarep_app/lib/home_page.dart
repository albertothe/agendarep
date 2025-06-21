import 'package:flutter/material.dart';
import 'agenda_page.dart';
import 'dashboard_page.dart';
import 'clientes_page.dart';
import 'sugestoes_page.dart';
import 'api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  final ApiService api = ApiService();

  final List<Widget> _pages = const [
    DashboardPage(),
    AgendaPage(),
    ClientesPage(),
    SugestoesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Clientes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb),
            label: 'Sugestões',
          ),
        ],
      ),
    );
  }
}
