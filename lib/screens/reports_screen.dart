import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/dance_database.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({
    super.key,
    required this.database,
    required this.refreshKey,
  });

  final DanceDatabase database;
  final int refreshKey;

  Future<void> _exportPdf(
    BuildContext context,
    List<Map<String, Object?>> evaluations,
    List<Map<String, Object?>> criteria,
  ) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'PULSO | Resultados de evaluación',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#176B58'),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Generado: ${DateTime.now().toLocal()}'),
          pw.SizedBox(height: 18),
          if (evaluations.isEmpty)
            pw.Text('Todavía no hay evaluaciones registradas.')
          else
            pw.TableHelper.fromTextArray(
              headers: [
                'Participante/grupo',
                'Carrera',
                'Turno',
                'Título del baile',
                'Promedio',
              ],
              data: evaluations
                  .map(
                    (row) => [
                      row['dancer_name'],
                      row['career'],
                      row['shift'],
                      row['dance_style'],
                      '${row['average_score']}/25',
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE5F0EB),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(7),
            ),
          pw.SizedBox(height: 22),
          pw.Text(
            'Promedio por criterio',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          ...criteria.map(
            (row) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Text(
                '${row['criterion_name']}: ${row['average_score']}/25 '
                '(${row['score_count']} notas)',
              ),
            ),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => document.save());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<List<Map<String, Object?>>>>(
      key: ValueKey(refreshKey),
      future: Future.wait([
        database.getEvaluationSummaries(),
        database.getCriterionPerformance(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('No se pudieron cargar los datos.'));
        }
        final evaluations = snapshot.data![0];
        final criteria = snapshot.data![1];
        return ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Consultas',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Generar PDF',
                  onPressed: () => _exportPdf(context, evaluations, criteria),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                ),
              ],
            ),
            const Text(
              'Resultados consolidados de las evaluaciones.',
              style: TextStyle(color: Color(0xFF6F7772)),
            ),
            const SizedBox(height: 22),
            const Text(
              'PROMEDIO POR CRITERIO',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 9),
            if (criteria.isEmpty)
              const _EmptyState(message: 'Aún no hay criterios disponibles.')
            else
              ...criteria.map((row) {
                final average = (row['average_score'] as num).toDouble();
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(row['criterion_name'] as String)),
                            Text(
                              '${average.toStringAsFixed(1)} / 25',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: average / 25,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(5),
                          backgroundColor: const Color(0xFFE9ECE8),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 17),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'EVALUACIONES',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ),
                Text('${evaluations.length} registros'),
              ],
            ),
            const SizedBox(height: 9),
            if (evaluations.isEmpty)
              const _EmptyState(message: 'Guarda una evaluación para ver resultados.')
            else
              ...evaluations.map((row) {
                final date = DateTime.tryParse(row['evaluated_at'] as String);
                final dateLabel = date == null
                    ? ''
                    : '${date.day.toString().padLeft(2, '0')}/'
                        '${date.month.toString().padLeft(2, '0')}/${date.year}';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 4,
                    ),
                    title: Text(row['dancer_name'] as String),
                    subtitle: Text(
                      '${row['career']} · ${row['shift']} · '
                      '${row['dance_style']} · '
                      '${row['evaluator_name']} · $dateLabel',
                    ),
                    trailing: Text(
                      '${row['average_score']}/25',
                      style: const TextStyle(
                        color: Color(0xFF176B58),
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(message, style: const TextStyle(color: Color(0xFF6F7772))),
      ),
    );
  }
}