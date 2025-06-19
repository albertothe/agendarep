import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'api_service.dart';

class ClientesPage extends StatefulWidget {
  const ClientesPage({super.key});

  @override
  State<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends State<ClientesPage> {
  final ApiService api = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> clientes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadClientes();
  }

  Future<void> _loadClientes() async {
    setState(() => loading = true);
    final res = await api.get('/clientes');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      final Map<String, Map<String, dynamic>> grouped = {};

      for (final row in data) {
        final id = row['id_cliente'].toString();
        grouped.putIfAbsent(id, () {
          return {
            'id_cliente': id,
            'nome': row['nome_cliente'],
            'telefone': row['telefone'],
            'grupos': <Map<String, dynamic>>[],
            'totalPotencial': 0.0,
            'totalComprado': 0.0,
          };
        });

        final grupo = {
          'id_grupo': row['id_grupo'],
          'nome_grupo': row['nome_grupo'],
          'potencial_compra': (row['potencial_compra'] as num?)?.toDouble() ?? 0,
          'valor_comprado': (row['valor_comprado'] as num?)?.toDouble() ?? 0,
        };
        grouped[id]!['grupos'].add(grupo);
        grouped[id]!['totalPotencial'] += grupo['potencial_compra'];
        grouped[id]!['totalComprado'] += grupo['valor_comprado'];
      }

      clientes = grouped.values.map((c) {
        final totalPotencial = c['totalPotencial'] as double;
        final totalComprado = c['totalComprado'] as double;
        final progresso = totalPotencial > 0
            ? ((totalComprado / totalPotencial) * 100).round()
            : 0;
        return {
          ...c,
          'progresso': progresso,
        };
      }).toList();
    } else {
      clientes = [];
    }

    setState(() => loading = false);
  }

  String _formatCurrency(double value) {
    return NumberFormat.simpleCurrency(locale: 'pt_BR').format(value);
  }

  List<Map<String, dynamic>> get _filteredClientes {
    final query = _searchController.text.toLowerCase();
    return clientes
        .where((c) => (c['nome'] as String).toLowerCase().contains(query))
        .toList();
  }

  void _openDetalhes(Map<String, dynamic> cliente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        final grupos = cliente['grupos'] as List<dynamic>;
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cliente['nome'],
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...grupos.map((g) {
                final pot = g['potencial_compra'] as double;
                final comp = g['valor_comprado'] as double;
                return ListTile(
                  title: Text(g['nome_grupo'] ?? ''),
                  subtitle: Text(
                      'Potencial: ${_formatCurrency(pot)}\nComprado: ${_formatCurrency(comp)}'),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadClientes,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'Buscar cliente',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          ..._filteredClientes.map((c) => Card(
                child: ListTile(
                  title: Text(c['nome']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (c['telefone'] != null)
                        Text(c['telefone'], style: const TextStyle(fontSize: 12)),
                      Text(
                        'Potencial: ${_formatCurrency(c['totalPotencial'])}',
                      ),
                      Text(
                        'Comprado: ${_formatCurrency(c['totalComprado'])}',
                      ),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${c['progresso']}%'),
                    ],
                  ),
                  onTap: () => _openDetalhes(c),
                ),
              ))
        ],
      ),
    );
  }
}
