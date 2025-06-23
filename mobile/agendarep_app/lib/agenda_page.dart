import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'api_service.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  final ApiService api = ApiService();
  DateTime semanaAtual = _inicioDaSemana(DateTime.now());
  List<dynamic> visitas = [];
  List<dynamic> clientes = [];
  List<dynamic> representantes = [];
  String repSelecionado = '';
  String perfil = '';
  String nomeUsuario = '';
  String codusuario = '';
  bool loading = true;

  final List<String> horas = _gerarHoras();

  static List<String> _gerarHoras() {
    final inicio = DateTime(0, 1, 1, 8, 0);
    final fim = DateTime(0, 1, 1, 17, 0);
    final horas = fim.difference(inicio).inHours + 1;
    return List.generate(horas, (i) {
      final t = inicio.add(Duration(hours: i));
      final h = t.hour.toString().padLeft(2, '0');
      return '$h:00';
    });
  }

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  static DateTime _inicioDaSemana(DateTime dt) {
    // Se for domingo (weekday = 7), vai para a próxima segunda
    if (dt.weekday == 7) {
      return dt.add(const Duration(days: 1));
    }
    // Senão, volta para a segunda da semana atual
    return dt.subtract(Duration(days: dt.weekday - 1));
  }

  // Dias da semana de segunda a sábado (6 dias)
  List<DateTime> get diasSemana =>
      List.generate(6, (i) => semanaAtual.add(Duration(days: i)));

  Future<void> _loadRepresentantes() async {
    try {
      final res = await api.get('/usuarios/representantes');
      if (res.statusCode == 200) {
        setState(() {
          representantes = jsonDecode(res.body);
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar representantes: $e');
    }
  }

  Future<void> _carregarDados() async {
    setState(() => loading = true);

    try {
      final token = await api.getToken();
      if (token != null) {
        final data = Jwt.parseJwt(token);
        perfil = data['perfil'] ?? '';
        nomeUsuario = data['nome'] ?? 'Usuario';
        codusuario = data['codusuario']?.toString() ?? '';

        if ((perfil == 'coordenador' || perfil == 'diretor') &&
            representantes.isEmpty) {
          await _loadRepresentantes();
        }
      }

      await Future.wait([_carregarVisitas(), _carregarClientes()]);
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _carregarVisitas() async {
    try {
      final df = DateFormat('yyyy-MM-dd');
      final inicio = df.format(semanaAtual);
      final fim = df
          .format(semanaAtual.add(const Duration(days: 5))); // 6 dias (seg-sab)

      String url = '/visitas?inicio=$inicio&fim=$fim';
      if (repSelecionado.isNotEmpty) {
        url += '&codusuario=$repSelecionado';
      }

      debugPrint('🔄 Carregando visitas: $url');

      final res = await api.get(url);
      debugPrint('📡 Status: ${res.statusCode}');
      debugPrint('📦 Response: ${res.body}');

      if (res.statusCode == 200) {
        final visitasData = jsonDecode(res.body) as List;
        setState(() {
          visitas = visitasData;
        });
        debugPrint('✅ ${visitas.length} visitas carregadas');

        // Debug cada visita
        for (var v in visitas) {
          debugPrint(
              '📋 Visita: ${v['data']} ${v['hora']} - ${v['nome_cliente'] ?? v['nome_cliente_temp']}');
        }
      } else {
        setState(() => visitas = []);
      }
    } catch (e) {
      debugPrint('❌ Erro: $e');
      setState(() => visitas = []);
    }
  }

  Future<void> _carregarClientes() async {
    try {
      String url = '/visitas/clientes/representante';
      if (repSelecionado.isNotEmpty) {
        url += '?codusuario=$repSelecionado';
      }

      final res = await api.get(url);

      if (res.statusCode == 200) {
        setState(() {
          clientes = jsonDecode(res.body);
        });
      } else {
        setState(() {
          clientes = [];
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar clientes: $e');
      setState(() => clientes = []);
    }
  }

  void _semanaAnterior() {
    setState(() {
      semanaAtual = semanaAtual.subtract(const Duration(days: 7));
    });
    _carregarDados();
  }

  void _proximaSemana() {
    setState(() {
      semanaAtual = semanaAtual.add(const Duration(days: 7));
    });
    _carregarDados();
  }

  void _abrirNovaVisita(String data, String hora) {
    showDialog(
      context: context,
      builder: (_) => NovaVisitaDialog(
        data: data,
        hora: hora,
        clientes: clientes,
        representantes: representantes,
        perfil: perfil,
        codusuarioLogado: codusuario,
        onSalvo: () {
          Navigator.of(context).pop();
          _carregarDados();
        },
      ),
    );
  }

  void _abrirConfirmar(Map visita) {
    // Apenas representantes podem confirmar agendamentos
    if (perfil != 'representante') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apenas representantes podem confirmar agendamentos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => ConfirmarVisitaDialog(
        visita: visita,
        onConfirmado: () {
          Navigator.of(context).pop();
          _carregarDados();
        },
      ),
    );
  }

  String _tituloSemana() {
    final df = DateFormat('dd/MM/yyyy');
    final inicio = df.format(semanaAtual);
    final fim = df.format(semanaAtual.add(const Duration(days: 5))); // Sábado
    return '$inicio - $fim';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F6FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _carregarDados,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 20),

                // Título e subtítulo padronizados
                const Text(
                  'Agenda Semanal',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1f2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  perfil == 'representante'
                      ? 'Gerencie suas visitas a clientes para a semana. Clique em um horário para agendar uma nova visita.'
                      : 'Visualize e gerencie agendamentos dos representantes. Apenas representantes podem confirmar visitas.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6b7280),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Filtro de representantes
                if (perfil == 'coordenador' || perfil == 'diretor')
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
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
                              child: Row(
                                mainAxisSize:
                                    MainAxisSize.min, // Adicionar esta linha
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: const Color(0xFF6366f1)
                                        .withOpacity(0.1),
                                    child: Text(
                                      r['nome']
                                          .toString()
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF6366f1),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    // Mudar de Expanded para Flexible
                                    child: Text(
                                      r['nome'],
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow
                                          .ellipsis, // Adicionar overflow
                                    ),
                                  ),
                                ],
                              ),
                            ))
                      ],
                      onChanged: (v) {
                        setState(() {
                          repSelecionado = v ?? '';
                        });
                        _carregarDados();
                      },
                    ),
                  ),

                // Controles de navegação da semana
                Container(
                  padding: const EdgeInsets.all(16),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _semanaAnterior,
                        icon: const Icon(Icons.chevron_left, size: 28),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF6366f1),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      Text(
                        _tituloSemana(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                      IconButton(
                        onPressed: _proximaSemana,
                        icon: const Icon(Icons.chevron_right, size: 28),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF6366f1),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Grid da agenda com coluna de horas fixa
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
                  child: Row(
                    children: [
                      // Coluna de horas fixa
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            bottomLeft: Radius.circular(12),
                          ),
                          border: Border(
                            right: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Header da coluna de horas
                            Container(
                              width: 70,
                              height: 50,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: const Center(
                                child: Text(
                                  'Hora',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF374151),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            // Células de horas
                            ...horas
                                .map((hora) => Container(
                                      width: 70,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.shade200,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          hora,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF6b7280),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ],
                        ),
                      ),

                      // Área scrollável dos dias
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Header dos dias
                                Row(
                                  children: diasSemana.map((dia) {
                                    final df = DateFormat('EEE dd/MM', 'pt_BR');
                                    return Container(
                                      width: 110,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        border: Border(
                                          right: BorderSide(
                                            color: Colors.grey.shade200,
                                            width: 1,
                                          ),
                                          bottom: BorderSide(
                                            color: Colors.grey.shade200,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          df.format(dia),
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF374151),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),

                                // Linhas de horários
                                ...horas
                                    .map((hora) => Row(
                                          children: diasSemana
                                              .map((dia) =>
                                                  _buildCelula(dia, hora))
                                              .toList(),
                                        ))
                                    .toList(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCelula(DateTime dia, String hora) {
    final dataStr = DateFormat('yyyy-MM-dd').format(dia);

    final visitasHorario = visitas.where((v) {
      final visitaDataRaw = v['data']?.toString() ?? '';
      final visitaHora = v['hora']?.toString() ?? '';

      // Extrair apenas a data da string ISO (2025-06-17T03:00:00.000Z -> 2025-06-17)
      String visitaData = '';
      if (visitaDataRaw.contains('T')) {
        visitaData = visitaDataRaw.split('T')[0];
      } else {
        visitaData = visitaDataRaw;
      }

      // Normalizar hora (08:00:00 -> 08:00)
      String horaVisita = visitaHora;
      if (visitaHora.contains(':')) {
        final parts = visitaHora.split(':');
        if (parts.length >= 2) {
          horaVisita =
              '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
        }
      }

      return visitaData == dataStr && horaVisita == hora;
    }).toList();

    final visita = visitasHorario.isNotEmpty ? visitasHorario.first : null;
    final temMultiplas = visitasHorario.length > 1;
    final isConfirmado = visita?['confirmado'] == true;

    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey.shade300;

    if (visita != null) {
      if (isConfirmado) {
        backgroundColor = const Color(0xFFDEF7FF); // Azul claro (confirmada)
        borderColor = const Color(0xFF0EA5E9); // Azul
      } else {
        backgroundColor = const Color(0xFFDCFCE7); // Verde claro (pendente)
        borderColor = const Color(0xFF16A34A); // Verde
      }
    }

    return GestureDetector(
      onTap: () {
        if (visita != null) {
          // Só permite editar se não estiver confirmado e for representante
          if (!isConfirmado) {
            _abrirConfirmar(visita);
          }
        } else {
          _abrirNovaVisita(dataStr, hora);
        }
      },
      child: Container(
        width: 110,
        height: 80,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            right: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: visita != null ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: visita != null
              ? Stack(
                  children: [
                    // Conteúdo principal com Flexible para evitar overflow
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Nome do cliente com overflow controlado
                          Flexible(
                            child: Text(
                              (visita['nome_cliente'] ??
                                  visita['nome_cliente_temp'] ??
                                  'Cliente') as String,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isConfirmado
                                    ? const Color(
                                        0xFF0369A1) // Azul escuro (confirmada)
                                    : const Color(
                                        0xFF15803D), // Verde escuro (pendente)
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 2),

                          // Ícone de confirmação
                          if (isConfirmado)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF0EA5E9),
                              size: 14,
                            )
                          else
                            Icon(
                              perfil == 'representante'
                                  ? Icons.check_circle_outline
                                  : Icons.visibility,
                              color: perfil == 'representante'
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF6b7280),
                              size: 14,
                            ),
                        ],
                      ),
                    ),

                    // Indicador de múltiplas visitas
                    if (temMultiplas &&
                        (perfil == 'coordenador' || perfil == 'diretor'))
                      Positioned(
                        top: 1,
                        right: 1,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366f1),
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '+${visitasHorario.length - 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                )
              : const Center(
                  child: Icon(
                    Icons.add,
                    size: 18,
                    color: Color(0xFF9ca3af),
                  ),
                ),
        ),
      ),
    );
  }
}

class NovaVisitaDialog extends StatefulWidget {
  final String data;
  final String hora;
  final List<dynamic> clientes;
  final List<dynamic> representantes;
  final String perfil;
  final String codusuarioLogado;
  final VoidCallback onSalvo;

  const NovaVisitaDialog({
    super.key,
    required this.data,
    required this.hora,
    required this.clientes,
    required this.representantes,
    required this.perfil,
    required this.codusuarioLogado,
    required this.onSalvo,
  });

  @override
  State<NovaVisitaDialog> createState() => _NovaVisitaDialogState();
}

class _NovaVisitaDialogState extends State<NovaVisitaDialog> {
  final ApiService api = ApiService();
  final TextEditingController obsController = TextEditingController();
  final TextEditingController nomeTempController = TextEditingController();
  final TextEditingController telefoneTempController = TextEditingController();
  final TextEditingController buscaClienteController = TextEditingController();
  List<dynamic> clientesFiltrados = [];
  bool mostrandoBusca = false;
  String? clienteSelecionado;
  String? representanteSelecionado;
  bool clienteTemporario = false;
  bool salvando = false;
  bool carregandoClientes = false;

  @override
  void initState() {
    super.initState();
    clientesFiltrados = widget.clientes;

    // Se for representante, seleciona automaticamente ele mesmo
    if (widget.perfil == 'representante') {
      representanteSelecionado = widget.codusuarioLogado;
    }

    // Listener para busca de clientes
    buscaClienteController.addListener(_filtrarClientes);
  }

  void _filtrarClientes() {
    final busca = buscaClienteController.text.toLowerCase();
    setState(() {
      if (busca.isEmpty) {
        clientesFiltrados = widget.clientes;
      } else {
        clientesFiltrados = widget.clientes.where((cliente) {
          final nome = cliente['nome'].toString().toLowerCase();
          return nome.contains(busca);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    buscaClienteController.dispose();
    super.dispose();
  }

  Future<void> _buscarClientesRepresentante(String codusuario) async {
    setState(() {
      carregandoClientes = true;
    });

    try {
      debugPrint('🔄 Buscando clientes do representante: $codusuario');

      final res = await api
          .get('/visitas/clientes/representante?codusuario=$codusuario');

      debugPrint('📡 Status busca clientes: ${res.statusCode}');
      debugPrint('📦 Response clientes: ${res.body}');

      if (res.statusCode == 200) {
        final clientesData = jsonDecode(res.body) as List;
        setState(() {
          clientesFiltrados = clientesData;
          clienteSelecionado = null;
          buscaClienteController.clear();
          mostrandoBusca = false;
          carregandoClientes = false;
        });
        debugPrint(
            '✅ ${clientesData.length} clientes carregados para representante $codusuario');

        for (var cliente in clientesData) {
          debugPrint(
              '👤 Cliente: ${cliente['nome']} (ID: ${cliente['id_cliente']})');
        }
      } else {
        setState(() {
          clientesFiltrados = [];
          clienteSelecionado = null;
          carregandoClientes = false;
        });
        debugPrint(
            '❌ Erro ao buscar clientes: ${res.statusCode} - ${res.body}');
      }
    } catch (e) {
      debugPrint('❌ Erro ao buscar clientes do representante: $e');
      setState(() {
        clientesFiltrados = [];
        clienteSelecionado = null;
        carregandoClientes = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada =
        DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.data));

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 10,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com ícone
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366f1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.event_note,
                        color: Color(0xFF6366f1),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nova Visita',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                          Text(
                            '$dataFormatada às ${widget.hora}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6b7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Seleção de representante (apenas para coordenador/diretor)
                if (widget.perfil == 'coordenador' ||
                    widget.perfil == 'diretor') ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (representanteSelecionado == null ||
                                representanteSelecionado!.isEmpty)
                            ? Colors.red.shade300
                            : Colors.grey.shade300,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: DropdownButtonFormField<String>(
                      value: representanteSelecionado,
                      decoration: InputDecoration(
                        labelText: 'Representante *',
                        labelStyle: TextStyle(
                          fontSize: 14,
                          color: (representanteSelecionado == null ||
                                  representanteSelecionado!.isEmpty)
                              ? Colors.red.shade600
                              : const Color(0xFF6b7280),
                        ),
                        prefixIcon: Icon(
                          Icons.person_pin,
                          color: (representanteSelecionado == null ||
                                  representanteSelecionado!.isEmpty)
                              ? Colors.red.shade600
                              : const Color(0xFF6366f1),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      items: widget.representantes
                          .map<DropdownMenuItem<String>>((r) =>
                              DropdownMenuItem<String>(
                                value: r['codusuario'].toString(),
                                child: Row(
                                  mainAxisSize:
                                      MainAxisSize.min, // Adicionar esta linha
                                  children: [
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: const Color(0xFF6366f1)
                                          .withOpacity(0.1),
                                      child: Text(
                                        r['nome']
                                            .toString()
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF6366f1),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      // Mudar de Expanded para Flexible
                                      child: Text(
                                        r['nome'],
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow
                                            .ellipsis, // Adicionar overflow
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          representanteSelecionado = v;
                        });
                        debugPrint('🔄 Representante selecionado: $v');

                        // Buscar clientes do representante selecionado
                        if (v != null && v.isNotEmpty) {
                          _buscarClientesRepresentante(v);
                        } else {
                          setState(() {
                            clientesFiltrados = widget.clientes;
                            clienteSelecionado = null;
                            buscaClienteController.clear();
                            mostrandoBusca = false;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Switch Cliente temporário
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366f1).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF6366f1).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: clienteTemporario,
                          onChanged: (v) =>
                              setState(() => clienteTemporario = v),
                          activeColor: const Color(0xFF6366f1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Cliente temporário',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Campo Cliente ou Nome temporário
                if (!clienteTemporario) ...[
                  // Campo de busca de cliente
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: buscaClienteController,
                      enabled:
                          !carregandoClientes, // Desabilitar durante carregamento
                      decoration: InputDecoration(
                        labelText: carregandoClientes
                            ? 'Carregando clientes...'
                            : 'Buscar cliente',
                        labelStyle: const TextStyle(fontSize: 14),
                        prefixIcon: carregandoClientes
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : const Icon(Icons.search,
                                color: Color(0xFF6366f1)),
                        suffixIcon: buscaClienteController.text.isNotEmpty &&
                                !carregandoClientes
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Color(0xFF6b7280)),
                                onPressed: () {
                                  buscaClienteController.clear();
                                  setState(() {
                                    clienteSelecionado = null;
                                    mostrandoBusca = false;
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onTap: () {
                        if (!carregandoClientes) {
                          setState(() {
                            mostrandoBusca = true;
                          });
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Lista de clientes filtrados
                  if (mostrandoBusca && clientesFiltrados.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: clientesFiltrados.length,
                        itemBuilder: (context, index) {
                          final cliente = clientesFiltrados[index];
                          final isSelected = clienteSelecionado ==
                              cliente['id_cliente'].toString();

                          return ListTile(
                            dense: true,
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: isSelected
                                  ? const Color(0xFF6366f1)
                                  : const Color(0xFF6366f1).withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                size: 16,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF6366f1),
                              ),
                            ),
                            title: Text(
                              cliente['nome'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? const Color(0xFF6366f1)
                                    : const Color(0xFF1f2937),
                              ),
                            ),
                            subtitle: cliente['telefone'] != null
                                ? Text(
                                    cliente['telefone'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6b7280),
                                    ),
                                  )
                                : null,
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF6366f1),
                                    size: 20,
                                  )
                                : null,
                            onTap: () {
                              setState(() {
                                clienteSelecionado =
                                    cliente['id_cliente'].toString();
                                buscaClienteController.text = cliente['nome'];
                                mostrandoBusca = false;
                              });
                            },
                          );
                        },
                      ),
                    ),

                  // Mensagem quando não encontrar clientes
                  if (mostrandoBusca &&
                      clientesFiltrados.isEmpty &&
                      buscaClienteController.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_off,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Nenhum cliente encontrado para "${buscaClienteController.text}"',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],

                if (clienteTemporario) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: nomeTempController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do cliente',
                        labelStyle: TextStyle(fontSize: 14),
                        prefixIcon:
                            Icon(Icons.person, color: Color(0xFF6366f1)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: telefoneTempController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefone',
                        labelStyle: TextStyle(fontSize: 14),
                        prefixIcon: Icon(Icons.phone, color: Color(0xFF6366f1)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Campo Observação
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: obsController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Observação',
                      labelStyle: TextStyle(fontSize: 14),
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.note_add, color: Color(0xFF6366f1)),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Botões
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            salvando ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(
                              color: Color(0xFF6366f1), width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'CANCELAR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6366f1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: salvando ? null : _salvarVisita,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366f1),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: salvando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'SALVAR',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }

  Future<void> _salvarVisita() async {
    // Validação para coordenador/diretor
    if ((widget.perfil == 'coordenador' || widget.perfil == 'diretor') &&
        (representanteSelecionado == null ||
            representanteSelecionado!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um representante para o agendamento'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validação de cliente
    if (!clienteTemporario &&
        (clienteSelecionado == null || clienteSelecionado!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um cliente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (clienteTemporario && nomeTempController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite o nome do cliente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => salvando = true);

    try {
      // Determinar qual código de usuário usar - LÓGICA CORRIGIDA
      String codusuarioParaEnviar;

      if (widget.perfil == 'coordenador' || widget.perfil == 'diretor') {
        // Para coordenador/diretor, SEMPRE usar o representante selecionado
        if (representanteSelecionado == null ||
            representanteSelecionado!.isEmpty) {
          throw Exception('Representante não selecionado');
        }
        codusuarioParaEnviar = representanteSelecionado!;
      } else {
        // Para representante, usar o próprio código
        codusuarioParaEnviar = widget.codusuarioLogado;
      }

      debugPrint('🔄 Salvando visita:');
      debugPrint('📋 Perfil: ${widget.perfil}');
      debugPrint('👤 Código usuário logado: ${widget.codusuarioLogado}');
      debugPrint('👥 Representante selecionado: $representanteSelecionado');
      debugPrint('📤 Código para enviar: $codusuarioParaEnviar');

      final dadosVisita = {
        'data': widget.data,
        'hora': widget.hora,
        'codusuario': codusuarioParaEnviar, // SEMPRE enviar o código correto
        if (clienteTemporario)
          'nome_cliente_temp': nomeTempController.text.trim(),
        if (clienteTemporario)
          'telefone_temp': telefoneTempController.text.trim(),
        if (!clienteTemporario) 'id_cliente': clienteSelecionado,
        'observacao': obsController.text.trim(),
      };

      debugPrint('📦 Dados enviados: $dadosVisita');

      final response = await api.post('/visitas', dadosVisita);

      debugPrint('📡 Status resposta: ${response.statusCode}');
      debugPrint('📥 Resposta: ${response.body}');

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Visita agendada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        widget.onSalvo();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar visita: ${response.body}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao salvar visita: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar visita: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => salvando = false);
    }
  }
}

class ConfirmarVisitaDialog extends StatefulWidget {
  final Map visita;
  final VoidCallback onConfirmado;

  const ConfirmarVisitaDialog({
    super.key,
    required this.visita,
    required this.onConfirmado,
  });

  @override
  State<ConfirmarVisitaDialog> createState() => _ConfirmarVisitaDialogState();
}

class _ConfirmarVisitaDialogState extends State<ConfirmarVisitaDialog> {
  final ApiService api = ApiService();
  late TextEditingController obs;
  bool confirmando = false;

  @override
  void initState() {
    super.initState();
    obs = TextEditingController(text: widget.visita['observacao'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final cliente = widget.visita['nome_cliente'] ??
        widget.visita['nome_cliente_temp'] ??
        'Cliente';
    final data =
        DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.visita['data']));
    final hora = widget.visita['hora'];

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 10,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF0FDF4),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com ícone
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF16A34A),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Confirmar Visita',
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

                // Informações da visita
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF16A34A).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            color: Color(0xFF16A34A),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cliente,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1f2937),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: Color(0xFF16A34A),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$data às $hora',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6b7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Campo Observação
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: obs,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observação da visita',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.note_add, color: Color(0xFF16A34A)),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Botões
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            confirmando ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                              color: Color(0xFF6b7280), width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'CANCELAR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6b7280),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: confirmando ? null : _confirmarVisita,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: confirmando
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'CONFIRMAR',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }

  Future<void> _confirmarVisita() async {
    setState(() => confirmando = true);

    try {
      final id = widget.visita['id'];

      // Atualizar observação
      await api.put('/visitas/$id/observacao', {'observacao': obs.text});

      // Confirmar visita
      await api.put('/visitas/$id/confirmar', {});

      widget.onConfirmado();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao confirmar visita'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => confirmando = false);
    }
  }
}
