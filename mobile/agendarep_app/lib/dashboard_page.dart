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
            sum + (double.tryParse(c['potencial_compra'].toString()) ?? 0.0),
      );

  double get totalComprado => clientes.fold(
        0,
        (sum, c) =>
            sum + (double.tryParse(c['valor_comprado'].toString()) ?? 0.0),
      );
  int get qtdClientes => clientes.map((c) => c['id_cliente']).toSet().length;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Painel Geral',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1f2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Visão geral das suas atividades, clientes\ne potencial de vendas.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6b7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Filtro de representantes
            if (perfil == 'coordenador' || perfil == 'diretor')
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: DropdownButtonFormField<String>(
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
              ),

            // Cards principais
            _buildMetricCard(
              icon: Icons.people,
              iconColor: const Color(0xFF6366f1),
              value: qtdClientes.toString(),
              label: 'Clientes Ativos',
            ),
            const SizedBox(height: 20),

            _buildMetricCard(
              icon: Icons.attach_money,
              iconColor: const Color(0xFFf59e0b),
              value: NumberFormat.simpleCurrency(locale: 'pt_BR')
                  .format(totalComprado),
              label: '',
            ),
            const SizedBox(height: 20),

            _buildMetricCard(
              icon: Icons.calendar_today,
              iconColor: const Color(0xFF6366f1),
              value: NumberFormat.simpleCurrency(locale: 'pt_BR')
                  .format(potencialTotal),
              label: '',
            ),
            const SizedBox(height: 20),

            _buildMetricCard(
              icon: Icons.check_circle,
              iconColor: const Color(0xFF10b981),
              value: visitasConfirmadas.toString(),
              label: 'Visitas Confirmadas',
            ),
            const SizedBox(height: 32),

            // Status das Visitas
            const Text(
              'Status das Visitas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1f2937),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10b981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$visitasConfirmadas Confirmadas',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1f2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 32),
                Text(
                  '$visitasPendentes Pendentes',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1f2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Lista de atividades recentes
            ..._buildRecentActivities(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      width: double.infinity,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1f2937),
                  ),
                ),
                if (label.isNotEmpty)
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6b7280),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRecentActivities() {
    final sorted = List<Map<String, dynamic>>.from(visitas)
      ..sort((a, b) {
        final dateA = DateTime.parse(a['data']);
        final dateB = DateTime.parse(b['data']);
        return dateB.compareTo(dateA);
      });
    final recent = sorted.take(10);
    final df = DateFormat('dd/MM/yyyy');

    return recent.map((v) {
      final cliente = v['nome_cliente'] ?? v['nome_cliente_temp'] ?? '';
      final data = df.format(DateTime.parse(v['data']));
      final hora = v['hora'];
      final obs = v['observacao'] ?? '';
      final isConfirmado = v['confirmado'] == true;

      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isConfirmado
                    ? const Color(0xFF10b981)
                    : const Color(0xFFf59e0b),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isConfirmado ? Icons.check : Icons.schedule,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1f2937),
                      ),
                      children: [
                        TextSpan(
                          text: isConfirmado
                              ? 'Visita confirmada com '
                              : 'Visita agendada com ',
                        ),
                        TextSpan(
                          text: cliente,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  if (obs.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        obs,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6b7280),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${data}às $hora',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6b7280),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
