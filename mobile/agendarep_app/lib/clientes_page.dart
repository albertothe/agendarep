import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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

    try {
      final res = await api.get('/clientes');
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);

        for (final row in data) {
          final id = row['id_cliente'].toString();
          clientesMap.putIfAbsent(
              id,
              () => {
                    'id_cliente': id,
                    'nome': row['nome_cliente'],
                    'telefone': row['telefone'],
                    'grupos': <Map<String, dynamic>>[],
                    'totalPotencial': 0.0,
                    'totalComprado': 0.0,
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
          return {...c, 'progresso': progresso};
        }).toList();

        hasMore = false; // sem paginação real
      } else {
        debugPrint('Erro HTTP: ${res.statusCode}');
      }
    } catch (e, s) {
      debugPrint('Erro ao carregar clientes: $e');
      debugPrintStack(stackTrace: s);
    } finally {
      if (page == 1) {
        setState(() => loading = false);
      } else {
        setState(() => loadingMore = false);
      }
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

  void _editarPotencial(
      Map<String, dynamic> cliente, Map<String, dynamic> grupo) {
    final controller = TextEditingController(
        text: (grupo['potencial_compra'] ?? '').toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Potencial'),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration:
              const InputDecoration(labelText: 'Potencial de compra'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final valor = double.tryParse(
                      controller.text.replaceAll(',', '.')) ??
                  grupo['potencial_compra'];
              await api.put(
                  '/clientes/${cliente['id_cliente']}/grupos/${grupo['id_grupo']}',
                  {'potencial_compra': valor});

              setState(() {
                final diff = valor - (grupo['potencial_compra'] as double);
                grupo['potencial_compra'] = valor;
                cliente['totalPotencial'] =
                    (cliente['totalPotencial'] as double) + diff;
                final totalPotencial = cliente['totalPotencial'] as double;
                final totalComprado = cliente['totalComprado'] as double;
                cliente['progresso'] = totalPotencial > 0
                    ? ((totalComprado / totalPotencial) * 100).round()
                    : 0;
              });

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _openDetalhes(Map<String, dynamic> cliente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        final grupos = cliente['grupos'] as List<dynamic>;
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
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
                    return Slidable(
                      key: ValueKey(g['id_grupo']),
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.25,
                        children: [
                          SlidableAction(
                            onPressed: (_) =>
                                _editarPotencial(cliente, g as Map<String, dynamic>),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            icon: Icons.edit,
                          ),
                        ],
                      ),
                      child: ListTile(
                        title: Text(g['nome_grupo'] ?? ''),
                        subtitle: Text(
                          'Potencial: ${_formatCurrency(pot)}\nComprado: ${_formatCurrency(comp)}',
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
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
                        Text(c['telefone'],
                            style: const TextStyle(fontSize: 12)),
                      Text(
                          'Potencial: ${_formatCurrency(c['totalPotencial'])}'),
                      Text('Comprado: ${_formatCurrency(c['totalComprado'])}'),
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
