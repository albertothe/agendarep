import 'dart:convert';
import 'package:flutter/material.dart';
import 'api_service.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  final ApiService api = ApiService();
  List<dynamic> visitas = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _carregarVisitas();
  }

  Future<void> _carregarVisitas() async {
    final res = await api.get('/visitas?inicio=2024-01-01&fim=2024-12-31');
    if (res.statusCode == 200) {
      setState(() {
        visitas = jsonDecode(res.body);
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agenda')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: visitas.length,
              itemBuilder: (context, index) {
                final v = visitas[index];
                return ListTile(
                  title: Text(v['nome_cliente'] ?? 'Sem nome'),
                  subtitle: Text('${v['data']} - ${v['hora']}'),
                );
              },
            ),
    );
  }
}
