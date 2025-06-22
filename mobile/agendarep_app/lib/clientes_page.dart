import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decode/jwt_decode.dart';
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
  List<dynamic> representantes = [];
  String repSelecionado = '';
  String perfil = '';
  String nomeUsuario = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRepresentantes() async {
    final res = await api.get('/usuarios/representantes');
    if (res.statusCode == 200) {
      representantes = jsonDecode(res.body);
    }
  }

  Future<void> _loadData() async {
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
    await _loadClientes(reset: true);
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
      final query =
          repSelecionado.isNotEmpty ? '?codusuario=$repSelecionado' : '';
      final res = await api.get('/clientes$query');
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

        // Ordenar por potencial (maior para menor)
        clientes.sort((a, b) => (b['totalPotencial'] as double)
            .compareTo(a['totalPotencial'] as double));

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

  void _openDetalhes(Map<String, dynamic> cliente) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final grupos = cliente['grupos'] as List<dynamic>;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366f1)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Color(0xFF6366f1),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cliente['nome'],
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1f2937),
                                        ),
                                      ),
                                      if (cliente['telefone'] != null)
                                        Text(
                                          cliente['telefone'],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF6b7280),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Resumo geral
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          _formatCurrencyShort(
                                              cliente['totalPotencial']),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF3b82f6),
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Text(
                                          'Potencial Total',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF6b7280),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.grey[300],
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          _formatCurrencyShort(
                                              cliente['totalComprado']),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF10b981),
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const Text(
                                          'Total Comprado',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF6b7280),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: Colors.grey[300],
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          '${cliente['progresso']}%',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFf59e0b),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const Text(
                                          'Progresso',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF6b7280),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Lista de grupos
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Grupos de Produtos',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1f2937),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366f1)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Deslize para editar',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF6366f1),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ...grupos.map((grupo) {
                              final pot = grupo['potencial_compra'] as double;
                              final comp = grupo['valor_comprado'] as double;
                              final progresso =
                                  pot > 0 ? ((comp / pot) * 100).round() : 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Slidable(
                                  key: ValueKey(grupo['id_grupo']),
                                  endActionPane: ActionPane(
                                    motion: const DrawerMotion(),
                                    extentRatio: 0.25,
                                    children: [
                                      SlidableAction(
                                        onPressed: (_) => _editarPotencial(
                                            cliente,
                                            grupo as Map<String, dynamic>,
                                            setModalState),
                                        backgroundColor:
                                            const Color(0xFF6366f1),
                                        foregroundColor: Colors.white,
                                        icon: Icons.edit,
                                        label: 'Editar',
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                grupo['nome_grupo'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1f2937),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: progresso == 0
                                                    ? const Color(0xFFfef2f2)
                                                    : const Color(0xFFdcfce7),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '$progresso%',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: progresso == 0
                                                      ? const Color(0xFFdc2626)
                                                      : const Color(0xFF16a34a),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Potencial Mensal',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF6b7280),
                                                    ),
                                                  ),
                                                  Text(
                                                    _formatCurrencyShort(pot),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF3b82f6),
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Comprado no Mês',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF6b7280),
                                                    ),
                                                  ),
                                                  Text(
                                                    _formatCurrencyShort(comp),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF10b981),
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _editarPotencial(Map<String, dynamic> cliente,
      Map<String, dynamic> grupo, StateSetter setModalState) {
    double valorAtual = grupo['potencial_compra'] as double;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366f1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Color(0xFF6366f1),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Editar Potencial',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1f2937),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Info do grupo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          grupo['nome_grupo'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1f2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cliente: ${cliente['nome']}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6b7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campo de valor com botões + e -
                  const Text(
                    'Potencial de Compra Mensal',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Controles de valor
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Valor atual
                        Text(
                          NumberFormat.simpleCurrency(locale: 'pt_BR')
                              .format(valorAtual),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1f2937),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Botões de incremento/decremento
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Botão -1000
                            _buildIncrementButton(
                              icon: Icons.remove,
                              label: '-R\$ 1.000',
                              onPressed: () {
                                setDialogState(() {
                                  valorAtual = (valorAtual - 1000)
                                      .clamp(0, double.infinity);
                                });
                              },
                              color: const Color(0xFFdc2626),
                            ),

                            // Botão -100
                            _buildIncrementButton(
                              icon: Icons.remove,
                              label: '-R\$ 100',
                              onPressed: () {
                                setDialogState(() {
                                  valorAtual = (valorAtual - 100)
                                      .clamp(0, double.infinity);
                                });
                              },
                              color: const Color(0xFFf59e0b),
                            ),

                            // Botão +100
                            _buildIncrementButton(
                              icon: Icons.add,
                              label: '+R\$ 100',
                              onPressed: () {
                                setDialogState(() {
                                  valorAtual += 100;
                                });
                              },
                              color: const Color(0xFF10b981),
                            ),

                            // Botão +1000
                            _buildIncrementButton(
                              icon: Icons.add,
                              label: '+R\$ 1.000',
                              onPressed: () {
                                setDialogState(() {
                                  valorAtual += 1000;
                                });
                              },
                              color: const Color(0xFF059669),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Botão Reset
                        TextButton(
                          onPressed: () {
                            setDialogState(() {
                              valorAtual = 0;
                            });
                          },
                          child: const Text(
                            'Zerar Valor',
                            style: TextStyle(
                              color: Color(0xFF6b7280),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botões
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Color(0xFF6366f1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6366f1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              final response = await api.put(
                                  '/clientes/${cliente['id_cliente']}/grupos/${grupo['id_grupo']}',
                                  {'potencial_compra': valorAtual});

                              if (response.statusCode == 200) {
                                // Atualizar os dados localmente
                                final diff = valorAtual -
                                    (grupo['potencial_compra'] as double);
                                grupo['potencial_compra'] = valorAtual;
                                cliente['totalPotencial'] =
                                    (cliente['totalPotencial'] as double) +
                                        diff;
                                final totalPotencial =
                                    cliente['totalPotencial'] as double;
                                final totalComprado =
                                    cliente['totalComprado'] as double;
                                cliente['progresso'] = totalPotencial > 0
                                    ? ((totalComprado / totalPotencial) * 100)
                                        .round()
                                    : 0;

                                // Atualizar a lista principal
                                setState(() {});

                                // Atualizar o modal
                                setModalState(() {});

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Potencial atualizado com sucesso!'),
                                      backgroundColor: Color(0xFF10b981),
                                    ),
                                  );
                                }
                              } else {
                                throw Exception('Erro na resposta do servidor');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Erro ao atualizar potencial'),
                                    backgroundColor: Color(0xFFdc2626),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366f1),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Salvar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIncrementButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: color, size: 20),
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // Calcular totalizadores
  Map<String, dynamic> get _totalizadores {
    final filtrados = _filteredClientes;
    return {
      'totalClientes': filtrados.length,
      'totalPotencial': filtrados.fold<double>(
          0, (sum, c) => sum + (c['totalPotencial'] as double)),
      'totalComprado': filtrados.fold<double>(
          0, (sum, c) => sum + (c['totalComprado'] as double)),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F6FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final totais = _totalizadores;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadClientes(reset: true),
          child: ListView(
            controller: _scrollController,
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
                'Gestão de Clientes',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1f2937),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Visualize, edite e gerencie as informações e o potencial de vendas de seus clientes.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6b7280),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Campo de busca
              Container(
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
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar cliente',
                    prefixIcon: Icon(Icons.search, color: Color(0xFF6b7280)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
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
                      _loadClientes(reset: true);
                    },
                  ),
                ),

              // Cards de métricas com altura fixa
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio:
                    0.9, // Proporção fixa para manter tamanho uniforme
                children: [
                  _buildMetricCard(
                    icon: Icons.people,
                    iconColor: const Color(0xFF6366f1),
                    value: totais['totalClientes'].toString(),
                    label: 'Total de\nClientes',
                  ),
                  _buildMetricCard(
                    icon: Icons.attach_money,
                    iconColor: const Color(0xFFf59e0b),
                    value: _formatCurrencyShort(totais['totalPotencial']),
                    label: 'Potencial\nTotal',
                  ),
                  _buildMetricCard(
                    icon: Icons.trending_up,
                    iconColor: const Color(0xFF10b981),
                    value: _formatCurrencyShort(totais['totalComprado']),
                    label: 'Total\nComprado',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Lista de clientes
              ..._filteredClientes
                  .map((cliente) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            '${cliente['id_cliente']} ${cliente['nome']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                'Potencial: ${_formatCurrencyShort(cliente['totalPotencial'])}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6b7280),
                                ),
                              ),
                              Text(
                                'Comprado: ${_formatCurrencyShort(cliente['totalComprado'])}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6b7280),
                                ),
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: cliente['progresso'] == 0
                                  ? const Color(0xFFfef2f2)
                                  : const Color(0xFFdcfce7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${cliente['progresso']}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: cliente['progresso'] == 0
                                    ? const Color(0xFFdc2626)
                                    : const Color(0xFF16a34a),
                              ),
                            ),
                          ),
                          onTap: () => _openDetalhes(cliente),
                        ),
                      ))
                  .toList(),

              if (loadingMore) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ]
            ],
          ),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
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

  String _formatCurrencyShort(double value) {
    if (value >= 1000000) {
      return 'R\$ ${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(0)}K';
    } else {
      return 'R\$ ${value.toStringAsFixed(0)}';
    }
  }
}
