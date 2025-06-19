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
  final ScrollController _scrollController = ScrollController();

  Map<String, Map<String, dynamic>> clientesMap = {};
  List<Map<String, dynamic>> clientes = [];
  bool loading = true;
  bool loadingMore = false;
  bool hasMore = true;
  int page = 1;
  final int limit = 50;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadClientes(reset: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClientes({bool reset = false}) async {
    if (reset) {
      page = 1;
      hasMore = true;
      clientesMap.clear();
      clientes.clear();
    }

    if (!hasMore) return;

    if (page == 1 && reset) {
      setState(() => loading = true);
    } else {
      setState(() => loadingMore = true);
    }

    // A API do backend retorna a lista completa de clientes sem paginacao.
    // Ajustamos a leitura para funcionar com esse formato.
    final res = await api.get('/clientes');
    if (res.statusCode == 200) {
      final List<dynamic> data = jsonDecode(res.body);
      final int total = data.length;

      for (final row in data) {
        final id = row['id_cliente'].toString();
        clientesMap.putIfAbsent(id, () {
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
          'potencial_compra':
              double.tryParse(row['potencial_compra'].toString()) ?? 0.0,
          'valor_comprado':
              double.tryParse(row['valor_comprado'].toString()) ?? 0.0,
        };
        clientesMap[id]!['grupos'].add(grupo);
        clientesMap[id]!['totalPotencial'] += grupo['potencial_compra'];
        clientesMap[id]!['totalComprado'] += grupo['valor_comprado'];
      }

      clientes = clientesMap.values.map((c) {
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

      hasMore = clientes.length < total;
      if (hasMore) page++;
    }

    if (page == 1) {
      setState(() => loading = false);
    } else {
      setState(() => loadingMore = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !loadingMore &&
        hasMore) {
      _loadClientes();
    }
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
      onRefresh: () => _loadClientes(reset: true),
      child: ListView(
        controller: _scrollController,
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
              )),
          if (loadingMore) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ]
        ],
      ),
    );
  }
}
