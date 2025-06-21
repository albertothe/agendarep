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
    final minutos = fim.difference(inicio).inMinutes;
    final passos = minutos ~/ 30 + 1; // inclui o horário final
    return List.generate(passos, (i) {
      final t = inicio.add(Duration(minutes: i * 30));
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m';
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
    final res = await api.get('/usuarios/representantes');
    if (res.statusCode == 200) {
      representantes = jsonDecode(res.body);
    }
  }

  Future<void> _carregarDados() async {
    setState(() => loading = true);
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
    setState(() => loading = false);
  }

  Future<void> _carregarVisitas() async {
    final df = DateFormat('yyyy-MM-dd');
    final inicio = df.format(semanaAtual);
    final fim = df.format(semanaAtual.add(const Duration(days: 6)));
    final repQuery =
        repSelecionado.isNotEmpty ? '&codusuario=$repSelecionado' : '';
    final res = await api.get('/visitas?inicio=$inicio&fim=$fim$repQuery');
    if (res.statusCode == 200) {
      visitas = jsonDecode(res.body);
    } else {
      visitas = [];
    }
  }

  Future<void> _carregarClientes() async {
    final repQuery =
        repSelecionado.isNotEmpty ? '?codusuario=$repSelecionado' : '';
    final res =
        await api.get('/visitas/clientes/representante$repQuery');
    if (res.statusCode == 200) {
      clientes = jsonDecode(res.body);
    } else {
      clientes = [];
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _carregarDados,
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
                    _carregarDados();
                  },
                ),
              if (perfil == 'coordenador' || perfil == 'diretor')
                const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _semanaAnterior,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    _tituloSemana(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    onPressed: _proximaSemana,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  border: TableBorder.all(color: Colors.grey.shade300),
                  children: [
                    _buildHeaderRow(),
                    ...horas.map(_buildLinhaHora),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Visitas Marcadas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ..._buildListaVisitas(),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildHeaderRow() {
    final df = DateFormat('EEE dd/MM', 'pt_BR');
    return TableRow(
      children: [
        const _HeaderCell('Hora'),
        ...diasSemana.map((d) => _HeaderCell(df.format(d))).toList(),
      ],
    );
  }

  TableRow _buildLinhaHora(String hora) {
    return TableRow(
      children: [
        _HeaderCell(hora),
        ...diasSemana.map((dia) => _buildCelula(dia, hora)).toList(),
      ],
    );
  }

  Widget _buildCelula(DateTime dia, String hora) {
    final dataStr = DateFormat('yyyy-MM-dd').format(dia);
    final visitasHorario = visitas
        .where((v) =>
            v['data'] == dataStr &&
            (v['hora'] as String).substring(0, 5) == hora)
        .toList();
    final visita = visitasHorario.isNotEmpty ? visitasHorario.first : null;

    final color = visita == null
        ? Colors.white
        : (visita['confirmado'] == true
            ? Colors.green.shade50
            : Colors.blue.shade50);

    return GestureDetector(
      onTap: () {
        if (visita != null) {
          _abrirConfirmar(visita);
        } else {
          _abrirNovaVisita(dataStr, hora);
        }
      },
      child: Container(
        height: 70,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color,
          border: Border(
            right: BorderSide(color: Colors.grey.shade300),
            bottom: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        child: visita != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (visita['nome_cliente'] ??
                        visita['nome_cliente_temp'] ??
                        '') as String,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (visita['observacao'] != null &&
                      visita['observacao'] != '')
                    Text(
                      visita['observacao'],
                      style: const TextStyle(fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              )
            : const Center(
                child: Icon(Icons.add, size: 16, color: Colors.grey)),
      ),
    );
  }

  List<Widget> _buildListaVisitas() {
    final sorted = List<Map<String, dynamic>>.from(visitas)
      ..sort((a, b) =>
          DateTime.parse(a['data']).compareTo(DateTime.parse(b['data'])));
    final df = DateFormat('dd/MM/yyyy');

    return sorted.map((v) {
      final cliente = v['nome_cliente'] ?? v['nome_cliente_temp'] ?? '';
      final data = df.format(DateTime.parse(v['data']));
      final hora = v['hora'];
      final obs = v['observacao'] ?? '';
      final isConfirmado = v['confirmado'] == true;

      return ListTile(
        leading: Icon(
          isConfirmado ? Icons.check_circle : Icons.schedule,
          color: isConfirmado ? Colors.green : Colors.orange,
        ),
        title: Text('$cliente - $hora'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data),
            if (obs.isNotEmpty) Text(obs),
          ],
        ),
        onTap: () => _abrirConfirmar(v),
      );
    }).toList();
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      alignment: Alignment.center,
      color: Colors.grey.shade100,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
  String? clienteSelecionado;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova Visita'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Cliente'),
            items: widget.clientes
                .map<DropdownMenuItem<String>>((c) => DropdownMenuItem<String>(
                      value: c['id_cliente'].toString(),
                      child: Text(c['nome']),
                    ))
                .toList(),
            onChanged: (v) => clienteSelecionado = v,
          ),
          TextField(
            controller: obsController,
            decoration: const InputDecoration(labelText: 'Observação'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            await api.post('/visitas', {
              'data': widget.data,
              'hora': widget.hora,
              'id_cliente': clienteSelecionado,
              'observacao': obsController.text,
            });
            widget.onSalvo();
          },
          child: const Text('Salvar'),
        ),
      ],
    );
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

  @override
  void initState() {
    super.initState();
    obs = TextEditingController(text: widget.visita['observacao'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmar Visita'),
      content: TextField(
        controller: obs,
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'Observação'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            final id = widget.visita['id'];
            await api.put('/visitas/$id/observacao', {'observacao': obs.text});
            await api.put('/visitas/$id/confirmar', {});
            widget.onConfirmado();
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}
