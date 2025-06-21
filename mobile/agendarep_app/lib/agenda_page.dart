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
    return dt.subtract(Duration(days: dt.weekday - 1));
  }

  List<DateTime> get diasSemana =>
      List.generate(7, (i) => semanaAtual.add(Duration(days: i)));

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
      final fim = df.format(semanaAtual.add(const Duration(days: 6)));

      // Ajustar URL para corresponder ao frontend web
      String url = '/visitas?inicio=$inicio&fim=$fim';
      if (repSelecionado.isNotEmpty) {
        url += '&representante=$repSelecionado';
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
        url += '?representante=$repSelecionado';
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
    final fim = df.format(semanaAtual.add(const Duration(days: 6)));
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
                        child: const Text(
                          'V',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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

                // Grid da agenda
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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DataTable(
                        columnSpacing: 4,
                        horizontalMargin: 8,
                        headingRowHeight: 50,
                        dataRowHeight: 80,
                        headingRowColor: MaterialStateProperty.all(
                          const Color(0xFFF8FAFC),
                        ),
                        border: TableBorder(
                          horizontalInside: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                          verticalInside: BorderSide(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        columns: [
                          const DataColumn(
                            label: SizedBox(
                              width: 60,
                              child: Text(
                                'Hora',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF374151),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          ...diasSemana.map((dia) {
                            final df = DateFormat('EEE dd/MM', 'pt_BR');
                            return DataColumn(
                              label: SizedBox(
                                width: 100,
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
                        ],
                        rows:
                            horas.map((hora) => _buildLinhaHora(hora)).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildLinhaHora(String hora) {
    return DataRow(
      cells: [
        DataCell(
          Container(
            width: 60,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border(
                right: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
            child: Center(
              child: Text(
                hora,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6b7280),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
        ...diasSemana.map((dia) => _buildCelula(dia, hora)).toList(),
      ],
    );
  }

  DataCell _buildCelula(DateTime dia, String hora) {
    final dataStr = DateFormat('yyyy-MM-dd').format(dia);

    final visitasHorario = visitas.where((v) {
      final visitaData = v['data']?.toString() ?? '';
      final visitaHora = v['hora']?.toString() ?? '';

      // Comparação simples e direta
      bool matchData = visitaData == dataStr;
      bool matchHora = visitaHora.startsWith(hora);

      return matchData && matchHora;
    }).toList();

    final visita = visitasHorario.isNotEmpty ? visitasHorario.first : null;

    if (visita != null) {
      debugPrint(
          '✅ Visita encontrada: $dataStr $hora - ${visita['nome_cliente'] ?? visita['nome_cliente_temp']}');
    }

    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey.shade300;

    if (visita != null) {
      debugPrint('🎨 Aplicando cores para visita encontrada');
      if (visita['confirmado'] == true) {
        backgroundColor = const Color(0xFFDCFCE7); // Verde claro
        borderColor = const Color(0xFF16A34A); // Verde
        debugPrint('🟢 Cor: Verde (confirmada)');
      } else {
        backgroundColor = const Color(0xFFDEF7FF); // Azul claro
        borderColor = const Color(0xFF0EA5E9); // Azul
        debugPrint('🔵 Cor: Azul (pendente)');
      }
    } else {
      debugPrint('⚪ Célula vazia - cor branca');
    }

    return DataCell(
      GestureDetector(
        onTap: () {
          if (visita != null) {
            _abrirConfirmar(visita);
          } else {
            _abrirNovaVisita(dataStr, hora);
          }
        },
        child: Container(
          width: 100,
          height: 70,
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.all(6),
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
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      (visita['nome_cliente'] ??
                          visita['nome_cliente_temp'] ??
                          'Cliente') as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: visita['confirmado'] == true
                            ? const Color(0xFF15803D)
                            : const Color(0xFF0369A1),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                    if (visita['confirmado'] == true)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Center(
                          child: Icon(
                            Icons.check_circle,
                            color: Color(0xFF16A34A),
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                )
              : const Center(
                  child: Icon(
                    Icons.add,
                    size: 20,
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
            // Título
            const Text(
              'Nova Visita',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1f2937),
              ),
            ),
            const SizedBox(height: 24),

            // Switch Cliente temporário
            Row(
              children: [
                Switch(
                  value: clienteTemporario,
                  onChanged: (v) => setState(() => clienteTemporario = v),
                  activeColor: const Color(0xFF6366f1),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Cliente temporário',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Campo Cliente ou Nome temporário
            if (!clienteTemporario)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Cliente',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
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
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: nomeTempController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do cliente',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: telefoneTempController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Campo Observação
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: obsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Observação',
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
                    onPressed: salvando ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF6366f1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
                        borderRadius: BorderRadius.circular(8),
                      ),
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

      debugPrint(
          'Resposta do servidor: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201) {
        widget.onSalvo();
      } else {
        // Mostrar erro
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao salvar visita')),
          );
        }
      }
    } catch (e) {
      debugPrint('Erro ao salvar visita: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar visita')),
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
    final info = '$cliente\n$data ${widget.visita['hora']}';

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
            // Título
            const Text(
              'Confirmar Visita',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1f2937),
              ),
            ),
            const SizedBox(height: 16),

            // Informações da visita
            Text(
              info,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6b7280),
              ),
            ),
            const SizedBox(height: 24),

            // Campo Observação
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: obs,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Observação',
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
                      side: const BorderSide(color: Color(0xFF6366f1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
                    onPressed: confirmando ? null : _confirmarVisita,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366f1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
      debugPrint('Erro ao confirmar visita: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao confirmar visita')),
        );
      }
    } finally {
      setState(() => confirmando = false);
    }
  }
}
