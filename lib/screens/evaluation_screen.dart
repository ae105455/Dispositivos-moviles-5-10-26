import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/dance_database.dart';
import '../design/design_styles.dart';

// Abraham Espinoza Vargas expone: formulario, validacion, guardado y PDF.

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
  final List<Map<String, Object?>> _criteria = [
    {'id': 1, 'name': 'Técnica'},
    {'id': 2, 'name': 'Expresión y arte'},
    {'id': 3, 'name': 'Coreografía'},
    {'id': 4, 'name': 'Vestuario y puesta en escena'},
  ];
  String? _career;
  String? _shift;
  bool _saving = false;

  int get _totalScore => _scoreControllers.values.fold<int>(
        0,
        (total, controller) => total + (int.tryParse(controller.text) ?? 0),
      );

  @override
  void initState() {
    super.initState();
    for (final criterion in _criteria) {
      _scoreControllers[criterion['id'] as int] = TextEditingController();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final scores = <int, double>{
      for (final criterion in _criteria)
        criterion['id'] as int:
            double.parse(_scoreControllers[criterion['id'] as int]!.text),
    };
    setState(() => _saving = true);
    try {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evaluación guardada en XAMPP.')),
      );
      widget.onSaved();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _exportEvaluationSheetPdf() async {
    final document = pw.Document();
    final criteria = _criteria.map((row) => row['name'] as String).toList();

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(20),
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

          const columnFlexes = [
            0.7,
            2.3,
            2.1,
            1.0,
            1.5,
            1.1,
            1.4,
            1.3,
            2.0,
            0.8
          ];
          final filledRow = <String>[
            '1',
            _nameController.text,
            _career ?? '',
            _shift ?? '',
            _titleController.text,
            ..._criteria.map((criterion) {
              final controller = _scoreControllers[criterion['id'] as int];
              return controller?.text ?? '';
            }),
            '$_totalScore',
          ];
          final bodyRows = List.generate(10, (rowIndex) {
            if (rowIndex == 0) return filledRow;
            return [
              '${rowIndex + 1}',
              ...List.filled(titleCells.length - 1, '')
            ];
          });

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text(
                  'FORMULARIO DE EVALUACION BAILE',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: _pdfGroupHeading('IDENTIFICACION'),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: _pdfGroupHeading('CARRERA'),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: _pdfGroupHeading('TURNO'),
                  ),
                  pw.Expanded(
                    flex: 8,
                    child: _pdfGroupHeading('ASPECTOS DE EVALUACION'),
                  ),
                ],
              ),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.7),
                columnWidths: {
                  for (var index = 0; index < columnFlexes.length; index++)
                    index: pw.FlexColumnWidth(columnFlexes[index]),
                },
                children: [
                  pw.TableRow(
                    children: titleCells
                        .map(
                          (label) => pw.Container(
                            height: 48,
                            alignment: pw.Alignment.center,
                            padding: const pw.EdgeInsets.all(3),
                            child: pw.Text(
                              label,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 7,
                                fontWeight: pw.FontWeight.bold,
                              ),
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
                              height: 28,
                              alignment: pw.Alignment.center,
                              padding: const pw.EdgeInsets.all(3),
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

  pw.Widget _pdfGroupHeading(String label) => pw.Container(
        height: 20,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 0.7),
        ),
        child: pw.Text(
          label,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
        ),
      );

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
    /* ESTRUCTURA DEL FORMULARIO: secciones apiladas dentro de una lista desplazable. */
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
                              style: ScreenDesign.pageTitle,
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Completa una ficha por participante o grupo.',
                              style: ScreenDesign.supportingText,
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
                  /* DISTRIBUCIÓN RESPONSIVA: carrera y turno pasan de una a dos columnas. */
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
                          color: ScreenDesign.muted,
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
                    color: ScreenDesign.greenTint,
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
                              color: ScreenDesign.green,
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

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Este campo es obligatorio.'
      : null;

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
