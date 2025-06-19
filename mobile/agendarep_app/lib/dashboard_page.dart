import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'api_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService api = ApiService();

  List<dynamic> clientes = [];
  List<dynamic> visitas = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => loading = true);

    try {
      final resClientes = await api.get('/clientes');
      if (resClientes.statusCode == 200) {
        clientes = jsonDecode(resClientes.body);
      }

      final now = DateTime.now();
      final start = now.subtract(Duration(days: now.weekday - 1));
      final end = start.add(const Duration(days: 6));
      final df = DateFormat('yyyy-MM-dd');
      final resVisitas = await api
          .get('/visitas?inicio=${df.format(start)}&fim=${df.format(end)}');
      if (resVisitas.statusCode == 200) {
        visitas = jsonDecode(resVisitas.body);
      }
    } finally {
      setState(() => loading = false);
    }
  }

  int get visitasConfirmadas =>
      visitas.where((v) => v['confirmado'] == true).length;
  int get visitasPendentes =>
      visitas.where((v) => v['confirmado'] != true).length;
  double get potencialTotal => clientes.fold(
      0,
      (sum, c) =>
          sum + ((c['potencial_compra'] as num?)?.toDouble() ?? 0.0));

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _buildCard('Clientes', clientes.length.toString(), Icons.people),
              _buildCard(
                  'Visitas', visitas.length.toString(), Icons.calendar_today),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildCard(
                  'Potencial',
                  NumberFormat.simpleCurrency(locale: 'pt_BR')
                      .format(potencialTotal),
                  Icons.monetization_on),
              _buildCard('Confirmadas', visitasConfirmadas.toString(),
                  Icons.check_circle),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Atividades recentes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ..._recentActivities(),
        ],
      ),
    );
  }

  Widget _buildCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon,
                  size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _recentActivities() {
    final sorted = List<Map<String, dynamic>>.from(visitas)
      ..sort((a, b) {
        final dateA = DateTime.parse('${a['data']} ${a['hora']}');
        final dateB = DateTime.parse('${b['data']} ${b['hora']}');
        return dateB.compareTo(dateA);
      });
    final recent = sorted.take(10);
    final df = DateFormat('dd/MM/yyyy');

    return recent.map((v) {
      final icon = v['confirmado'] == true
          ? Icons.check_circle
          : Icons.schedule;
      final color =
          v['confirmado'] == true ? Colors.green : Colors.orange;
      final cliente =
          v['nome_cliente'] ?? v['nome_cliente_temp'] ?? '';
      final data = df.format(DateTime.parse(v['data']));
      final hora = v['hora'];
      final obs = v['observacao'];
      return ListTile(
        leading: Icon(icon, color: color),
        title: Text(
            '${v['confirmado'] == true ? 'Visita confirmada' : 'Visita agendada'} com $cliente'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$data às $hora'),
            if (obs != null && obs != '')
              Text(obs, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }).toList();
  }
}
