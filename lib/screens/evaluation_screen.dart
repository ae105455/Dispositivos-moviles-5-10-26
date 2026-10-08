import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/dance_database.dart';

class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({
    super.key,
    required this.database,
    required this.onSaved,
  });

  final DanceDatabase database;
  final VoidCallback onSaved;

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  static const _careers = [
    'Secretariado Ejecutivo',
    'Contaduría General',
    'Sistemas Informáticos',
    'Mercadotecnia',
    'Turismo',
    'Gastronomía',
    'Idioma Inglés',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _evaluatorController = TextEditingController();
  final _positionController = TextEditingController();
  final _signatureController = TextEditingController();
  final _notesController = TextEditingController();
  final Map<int, TextEditingController> _scoreControllers = {};
  String? _career;
  String? _shift;
  List<Map<String, Object?>> _criteria = [];
  bool _loading = true;
  bool _saving = false;

  int get _totalScore => _scoreControllers.values.fold<int>(
    0,
    (total, controller) => total + (int.tryParse(controller.text) ?? 0),
  );

  @override
  void initState() {
    super.initState();
    _loadCriteria();
  }

  Future<void> _loadCriteria() async {
    final criteria = await widget.database.getCriteria();
    if (!mounted) return;
    setState(() {
      _criteria = criteria;
      for (final criterion in criteria) {
        _scoreControllers[criterion['id'] as int] = TextEditingController();
      }
      _loading = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final scores = <int, double>{
      for (final criterion in _criteria)
        criterion['id'] as int:
            double.parse(_scoreControllers[criterion['id'] as int]!.text),
    };
    setState(() => _saving = true);
    await widget.database.saveEvaluation(
      dancerName: _nameController.text,
      career: _career!,
      shift: _shift!,
      evaluatorName: _evaluatorController.text,
      evaluatorPosition: _positionController.text,
      danceTitle: _titleController.text,
      signature: _signatureController.text,
      scores: scores,
      notes: _notesController.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evaluación guardada correctamente.')),
    );
    widget.onSaved();
  }

  Future<void> _exportEvaluationSheetPdf() async {
    final document = pw.Document();
    final criteria = _criteria.map((row) => row['name'] as String).toList();

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(18),
        build: (pw.Context context) {
          final titleCells = [
            'Nro.',
            'PARTICIPANTE O GRUPO',
            'CARRERA',
            'TURNO',
            'TITULO DEL BAILE',
            ...criteria,
            'TOTAL',
          ];

          final bodyRows = List.generate(7, (rowIndex) {
            final cells = <dynamic>[];
            cells.add('${rowIndex + 1}');
            cells.add(_nameController.text);
            cells.add(_career ?? '');
            cells.add(_shift ?? '');
            cells.add(_titleController.text);
            for (final _ in criteria) {
              cells.add('');
            }
            cells.add('');
            return cells;
          });

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text(
                  'FORMULARIO DE EVALUACION BAILE',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.7),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.9),
                  1: const pw.FlexColumnWidth(2.0),
                  2: const pw.FlexColumnWidth(1.7),
                  3: const pw.FlexColumnWidth(1.1),
                  4: const pw.FlexColumnWidth(1.6),
                  5: const pw.FlexColumnWidth(1.1),
                  6: const pw.FlexColumnWidth(1.3),
                  7: const pw.FlexColumnWidth(1.2),
                  8: const pw.FlexColumnWidth(1.7),
                  9: const pw.FlexColumnWidth(0.9),
                },
                children: [
                  pw.TableRow(
                    children: titleCells
                        .map(
                          (label) => pw.Container(
                            alignment: pw.Alignment.center,
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              label,
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  ...bodyRows.map(
                    (row) => pw.TableRow(
                      children: row
                          .map(
                            (cell) => pw.Container(
                              height: 20,
                              alignment: pw.Alignment.centerLeft,
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 3,
                              ),
                              child: pw.Text(
                                cell.toString(),
                                maxLines: 1,
                                style: const pw.TextStyle(fontSize: 7),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'NOMBRE DEL JURADO:',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 18),
                        pw.Text(
                          'FIRMA',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 40),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'CARGO:',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => document.save());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _evaluatorController.dispose();
    _positionController.dispose();
    _signatureController.dispose();
    _notesController.dispose();
    for (final controller in _scoreControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Formulario de evaluación de baile',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Completa una ficha por participante o grupo.',
                              style: TextStyle(color: Color(0xFF6F7772)),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Imprimir ficha',
                        onPressed: _exportEvaluationSheetPdf,
                        icon: const Icon(Icons.print_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('PARTICIPANTE'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Participante o grupo',
                      prefixIcon: Icon(Icons.groups_2_outlined),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth > 540;
                      final career = DropdownButtonFormField<String>(
                        initialValue: _career,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Carrera'),
                        items: _careers
                            .map(
                              (career) => DropdownMenuItem(
                                value: career,
                                child: Text(career),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _career = value),
                        validator: (value) =>
                            value == null ? 'Selecciona la carrera.' : null,
                      );
                      final shift = DropdownButtonFormField<String>(
                        initialValue: _shift,
                        decoration: const InputDecoration(labelText: 'Turno'),
                        items: const ['Mañana', 'Noche']
                            .map(
                              (shift) => DropdownMenuItem(
                                value: shift,
                                child: Text(shift),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setState(() => _shift = value),
                        validator: (value) =>
                            value == null ? 'Selecciona el turno.' : null,
                      );
                      if (!wide) {
                        return Column(
                          children: [
                            career,
                            const SizedBox(height: 12),
                            shift,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: career),
                          const SizedBox(width: 12),
                          Expanded(child: shift),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('PRESENTACIÓN'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Título del baile',
                      prefixIcon: Icon(Icons.music_note_rounded),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(child: _sectionTitle('ASPECTOS DE EVALUACIÓN')),
                      const Text(
                        '25 pts. cada uno',
                        style: TextStyle(
                          color: Color(0xFF6F7772),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._criteria.map((criterion) {
                    final id = criterion['id'] as int;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ScoreField(
                        name: criterion['name'] as String,
                        controller: _scoreControllers[id]!,
                        onChanged: (_) => setState(() {}),
                      ),
                    );
                  }),
                  Card(
                    color: const Color(0xFFE5F0EB),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'TOTAL',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          Text(
                            '$_totalScore / 100 pts.',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Color(0xFF176B58),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _sectionTitle('JURADO'),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _evaluatorController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del jurado',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _positionController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Cargo',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _signatureController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Firma (escriba su nombre)',
                      prefixIcon: Icon(Icons.draw_outlined),
                    ),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observaciones (opcional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _saving ? 'Guardando…' : 'Guardar evaluación',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Este campo es obligatorio.' : null;

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
  );
}

class _ScoreField extends StatelessWidget {
  const _ScoreField({
    required this.name,
    required this.controller,
    required this.onChanged,
  });

  final String name;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: name,
        suffixText: '/ 25 pts.',
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
      validator: (value) {
        final score = int.tryParse(value ?? '');
        if (score == null) return 'Ingresa una puntuación.';
        if (score < 0 || score > 25) return 'La nota debe estar entre 0 y 25.';
        return null;
      },
    );
  }
}
