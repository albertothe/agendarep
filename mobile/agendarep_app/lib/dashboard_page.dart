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
  String nomeUsuario = '';
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
        nomeUsuario = data['nome'] ?? 'Usuario';
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
        backgroundColor: Color(0xFFF5F6FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header padronizado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'AgendaRep',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366f1),
                    ),
                  ),
                  PopupMenuButton<String>(
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF6366f1),
                      child: Text(
                        nomeUsuario.isNotEmpty
                            ? nomeUsuario[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
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
              const SizedBox(height: 24),

              // Título e subtítulo padronizados
              const Text(
                'Painel Geral',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1f2937),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Visão geral das suas atividades, clientes e potencial de vendas.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6b7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Filtro de representantes
              if (perfil == 'coordenador' || perfil == 'diretor')
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: repSelecionado.isEmpty ? null : repSelecionado,
                    decoration: const InputDecoration(
                      labelText: 'Representante',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
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

              // Cards de métricas com altura fixa
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio:
                    1.1, // Proporção fixa para manter tamanho uniforme
                children: [
                  _buildCard(
                      icon: Icons.people,
                      value: qtdClientes.toString(),
                      label: 'Clientes Ativos',
                      color: const Color(0xFF6366f1)),
                  _buildCard(
                      icon: Icons.monetization_on,
                      value: _formatCurrencyShort(potencialTotal),
                      label: 'Potencial Total',
                      color: const Color(0xFFf59e0b)),
                  _buildCard(
                      icon: Icons.calendar_today,
                      value: visitas.length.toString(),
                      label: 'Visitas na Semana',
                      color: const Color(0xFF8b5cf6)),
                  _buildCard(
                      icon: Icons.show_chart,
                      value: _formatCurrencyShort(totalComprado),
                      label: 'Total Comprado',
                      color: const Color(0xFF10b981)),
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1f2937),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6b7280),
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Função para formatar valores grandes de forma compacta
  String _formatCurrencyShort(double value) {
    if (value >= 1000000) {
      return 'R\$ ${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(0)}K';
    } else {
      return 'R\$ ${value.toStringAsFixed(0)}';
    }
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConfirmado ? Icons.check_circle : Icons.schedule,
                  size: 18,
                  color: isConfirmado
                      ? const Color(0xFF10b981)
                      : const Color(0xFFf59e0b),
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
                child:
                    Text(obs, style: const TextStyle(color: Color(0xFF6b7280))),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '$data às $hora',
                style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af)),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
