import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  bool loading = true;

  final horas = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00'
  ];

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

  Future<void> _carregarDados() async {
    setState(() => loading = true);
    await Future.wait([_carregarVisitas(), _carregarClientes()]);
    setState(() => loading = false);
  }

  Future<void> _carregarVisitas() async {
    final df = DateFormat('yyyy-MM-dd');
    final inicio = df.format(semanaAtual);
    final fim = df.format(semanaAtual.add(const Duration(days: 6)));
    final res = await api.get('/visitas?inicio=$inicio&fim=$fim');
    if (res.statusCode == 200) {
      visitas = jsonDecode(res.body);
    } else {
      visitas = [];
    }
  }

  Future<void> _carregarClientes() async {
    final res = await api.get('/visitas/clientes/representante');
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
    return Scaffold(
      appBar: AppBar(title: const Text('AgendaRep')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
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
                ],
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
