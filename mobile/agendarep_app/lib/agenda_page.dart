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
        onSalvo: () {
          Navigator.of(context).pop();
          _carregarDados();
        },
      ),
    );
  }

  void _abrirConfirmar(Map visita) {
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
                const SizedBox(height: 24),

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
                const Text(
                  'Gerencie suas visitas a clientes para a semana. Clique em um horário para agendar uma nova visita.',
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

                const SizedBox(height: 16),

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
          // Só permite editar se não estiver confirmado
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
          padding: const EdgeInsets.all(4), // Reduzido de 6 para 4
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
                                fontSize: 10, // Reduzido de 11 para 10
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

                          const SizedBox(height: 2), // Espaçamento reduzido

                          // Ícone de confirmação
                          if (isConfirmado)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF0EA5E9),
                              size: 14, // Reduzido de 16 para 14
                            )
                          else
                            const Icon(
                              Icons.check_circle_outline,
                              color: Color(0xFF16A34A),
                              size: 14, // Reduzido de 16 para 14
                            ),
                        ],
                      ),
                    ),

                    // Indicador de múltiplas visitas
                    if (temMultiplas &&
                        (perfil == 'coordenador' || perfil == 'diretor'))
                      Positioned(
                        top: 1, // Reduzido de 2 para 1
                        right: 1, // Reduzido de 2 para 1
                        child: Container(
                          width: 18, // Reduzido de 20 para 18
                          height: 18, // Reduzido de 20 para 18
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366f1),
                            borderRadius: BorderRadius.circular(9), // Ajustado
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
                                fontSize: 9, // Reduzido de 10 para 9
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
                    size: 18, // Reduzido de 20 para 18
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
  final VoidCallback onSalvo;

  const NovaVisitaDialog({
    super.key,
    required this.data,
    required this.hora,
    required this.clientes,
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
  String? clienteSelecionado;
  bool clienteTemporario = false;
  bool salvando = false;

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
          maxHeight: MediaQuery.of(context).size.height * 0.8, // Limita altura
          maxWidth: MediaQuery.of(context).size.width * 0.9, // Limita largura
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
          // Adicionado scroll
          child: Padding(
            padding: const EdgeInsets.all(24), // Reduzido de 28 para 24
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com ícone
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366f1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.event_note,
                        color: Color(0xFF6366f1),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nova Visita',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1f2937),
                            ),
                          ),
                          Text(
                            '$dataFormatada às ${widget.hora}',
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
                const SizedBox(height: 28),

                // Switch Cliente temporário
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366f1).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6366f1).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Switch(
                        value: clienteTemporario,
                        onChanged: (v) => setState(() => clienteTemporario = v),
                        activeColor: const Color(0xFF6366f1),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Cliente temporário',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Campo Cliente ou Nome temporário
                if (!clienteTemporario)
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
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Selecionar Cliente',
                        prefixIcon:
                            Icon(Icons.person, color: Color(0xFF6366f1)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      items: widget.clientes
                          .map<DropdownMenuItem<String>>(
                              (c) => DropdownMenuItem<String>(
                                    value: c['id_cliente'].toString(),
                                    child: Text(c['nome']),
                                  ))
                          .toList(),
                      onChanged: (v) => setState(() => clienteSelecionado = v),
                    ),
                  ),

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
                        prefixIcon:
                            Icon(Icons.person, color: Color(0xFF6366f1)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
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
                        prefixIcon: Icon(Icons.phone, color: Color(0xFF6366f1)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                ],

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
                    controller: obsController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Observação',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.note_add, color: Color(0xFF6366f1)),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Botões
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            salvando ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: salvando ? null : _salvarVisita,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366f1),
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
    setState(() => salvando = true);

    try {
      final response = await api.post('/visitas', {
        'data': widget.data,
        'hora': widget.hora,
        if (clienteTemporario) 'nome_cliente_temp': nomeTempController.text,
        if (clienteTemporario) 'telefone_temp': telefoneTempController.text,
        if (!clienteTemporario) 'id_cliente': clienteSelecionado,
        'observacao': obsController.text,
      });

      if (response.statusCode == 201) {
        widget.onSalvo();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao salvar visita'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar visita'),
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
          maxHeight: MediaQuery.of(context).size.height * 0.8, // Limita altura
          maxWidth: MediaQuery.of(context).size.width * 0.9, // Limita largura
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
          // Adicionado scroll
          child: Padding(
            padding: const EdgeInsets.all(24), // Reduzido de 28 para 24
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com ícone
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF16A34A),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Confirmar Visita',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Informações da visita
                Container(
                  padding: const EdgeInsets.all(20),
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
                                fontSize: 18,
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
                              fontSize: 16,
                              color: Color(0xFF6b7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

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
                    maxLines: 4,
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

                const SizedBox(height: 32),

                // Botões
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            confirmando ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: confirmando ? null : _confirmarVisita,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
