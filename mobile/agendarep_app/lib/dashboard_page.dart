// Adaptado para layout moderno estilo login
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
        if ((perfil == 'coordenador' || perfil == 'diretor') &&
            representantes.isEmpty) {
          await _loadRepresentantes();
        }
      }

      final clienteQuery =
          repSelecionado.isNotEmpty ? '?codusuario=$repSelecionado' : '';
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
          sum + (double.tryParse(c['potencial_compra'].toString()) ?? 0.0));
  double get totalComprado => clientes.fold(
      0,
      (sum, c) =>
          sum + (double.tryParse(c['valor_comprado'].toString()) ?? 0.0));
  int get qtdClientes => clientes.map((c) => c['id_cliente']).toSet().length;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  const Text('AgendaRep',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.indigo,
                      )),
                  const Spacer(),
                  PopupMenuButton<String>(
                    icon: const CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.deepPurple,
                      child: Text('V', style: TextStyle(color: Colors.white)),
                    ),
                    onSelected: (value) async {
                      if (value == 'logout') {
                        await api.setToken('');
                        if (!mounted) return;
                        Navigator.pushReplacementNamed(context, '/');
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Text('Sair'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Painel Geral',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Visão geral de suas atividades,  clientes e potencial de vendas.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              if (perfil == 'coordenador' || perfil == 'diretor')
                DropdownButtonFormField<String>(
                  value: repSelecionado.isEmpty ? null : repSelecionado,
                  decoration: const InputDecoration(
                    labelText: 'Representante',
                    border: OutlineInputBorder(),
                  ),
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
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildCard(
                      icon: Icons.people,
                      value: qtdClientes.toString(),
                      label: 'Clientes Ativos',
                      color: Colors.deepPurple),
                  _buildCard(
                      icon: Icons.monetization_on,
                      value: currency.format(potencialTotal),
                      label: 'Potencial Total',
                      color: Colors.orange),
                  _buildCard(
                      icon: Icons.calendar_today,
                      value: visitas.length.toString(),
                      label: 'Visitas na Semana',
                      color: Colors.indigo),
                  _buildCard(
                      icon: Icons.show_chart,
                      value: currency.format(totalComprado),
                      label: 'Total Comprado',
                      color: Colors.green),
                ],
              ),
              const SizedBox(height: 30),
              const Text('Atividades Recentes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ..._buildRecentActivities(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
      {required IconData icon,
      required String value,
      required String label,
      required Color color}) {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 24,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecentActivities() {
    final sorted = List<Map<String, dynamic>>.from(visitas)
      ..sort((a, b) =>
          DateTime.parse(b['data']).compareTo(DateTime.parse(a['data'])));
    final recent = sorted.take(10);
    final df = DateFormat('dd/MM/yyyy');

    return recent.map((v) {
      final cliente = v['nome_cliente'] ?? v['nome_cliente_temp'] ?? '';
      final data = df.format(DateTime.parse(v['data']));
      final hora = v['hora'];
      final obs = v['observacao'] ?? '';
      final isConfirmado = v['confirmado'] == true;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConfirmado ? Icons.check_circle : Icons.schedule,
                  size: 18,
                  color: isConfirmado ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: isConfirmado
                          ? 'Visita confirmada com '
                          : 'Visita agendada com ',
                      children: [
                        TextSpan(
                          text: cliente,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (obs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(obs, style: const TextStyle(color: Colors.black54)),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$data às $hora',
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
