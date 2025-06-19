import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decode/jwt_decode.dart';

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
  List<dynamic> representantes = [];
  String repSelecionado = '';
  String perfil = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadRepresentantes() async {
    final res = await api.get('/usuarios/representantes');
    if (res.statusCode == 200) {
      representantes = jsonDecode(res.body);
    }
  }

  Future<void> _loadData() async {
    setState(() => loading = true);

    try {
      final token = await api.getToken();
      if (token != null) {
        final data = Jwt.parseJwt(token);
        perfil = data['perfil'] ?? '';
        if ((perfil == 'coordenador' || perfil == 'diretor') && representantes.isEmpty) {
          await _loadRepresentantes();
        }
      }

      final clienteQuery = repSelecionado.isNotEmpty ? '?codusuario=$repSelecionado' : '';
      final resClientes = await api.get('/clientes$clienteQuery');
      if (resClientes.statusCode == 200) {
        clientes = jsonDecode(resClientes.body);
      } else {
        clientes = [];
      }

      final now = DateTime.now();
      final start = now.subtract(Duration(days: now.weekday - 1));
      final end = start.add(const Duration(days: 6));
      final df = DateFormat('yyyy-MM-dd');
      final visitasQuery =
          '?inicio=${df.format(start)}&fim=${df.format(end)}${repSelecionado.isNotEmpty ? '&codusuario=$repSelecionado' : ''}';
      final resVisitas = await api.get('/visitas$visitasQuery');
      if (resVisitas.statusCode == 200) {
        visitas = jsonDecode(resVisitas.body);
      } else {
        visitas = [];
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
  double get totalComprado => clientes.fold(
      0,
      (sum, c) => sum + ((c['valor_comprado'] as num?)?.toDouble() ?? 0.0));
  int get qtdClientes => clientes.map((c) => c['id_cliente']).toSet().length;

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
          if (perfil == 'coordenador' || perfil == 'diretor')
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<String>(
                value: repSelecionado.isEmpty ? null : repSelecionado,
                decoration: const InputDecoration(labelText: 'Representante'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Todos')),
                  ...representantes.map((r) => DropdownMenuItem(
                        value: r['codusuario'].toString(),
                        child: Text(r['nome']),
                      ))
                ],
                onChanged: (v) {
                  setState(() => repSelecionado = v ?? '');
                  _loadData();
                },
              ),
            ),
          Row(
            children: [
              _buildCard('Clientes', qtdClientes.toString(), Icons.people),
              _buildCard(
                  'Potencial',
                  NumberFormat.simpleCurrency(locale: 'pt_BR')
                      .format(potencialTotal),
                  Icons.monetization_on),
              _buildCard(
                  'Comprado',
                  NumberFormat.simpleCurrency(locale: 'pt_BR')
                      .format(totalComprado),
                  Icons.trending_up),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildCard(
                  'Visitas', visitas.length.toString(), Icons.calendar_today),
              _buildCard('Confirmadas', visitasConfirmadas.toString(),
                  Icons.check_circle),
              _buildStatusCard(),
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

  Widget _buildStatusCard() {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text('$visitasConfirmadas Confirmadas'),
                    backgroundColor: Colors.green.shade50,
                  ),
                  Chip(
                    label: Text('$visitasPendentes Pendentes'),
                    backgroundColor: Colors.orange.shade50,
                  ),
                ],
              )
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
