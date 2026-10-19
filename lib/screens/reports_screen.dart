import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../data/dance_database.dart';
import '../design/design_styles.dart';

// Abraham Espinoza Vargas expone: consultas visuales y reporte PDF.

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({
    super.key,
    required this.database,
    required this.refreshKey,
    required this.active,
  });

  final DanceDatabase database;
  final int refreshKey;
  final bool active;

  Future<void> _exportPdf(
    BuildContext context,
    List<Map<String, Object?>> evaluations,
    List<Map<String, Object?>> criteria,
  ) async {
    final document = pw.Document();
    String formatScore(Object? value) =>
        (num.tryParse('$value') ?? 0).toStringAsFixed(1);
    final maximumCriteria = criteria.length;
    final maximumScore = maximumCriteria * 25;
    int scoredCriteria(Map<String, Object?> row) =>
        int.tryParse('${row['scored_criteria']}') ?? maximumCriteria;
    String evaluationSignature(Map<String, Object?> row) {
      final signature = '${row['signature'] ?? ''}'.trim();
      return signature.isEmpty ? ' ' : signature;
    }

    document.addPage(
      pw.MultiPage(
        margin: const pw.EdgeInsets.all(32),
        pageFormat: PdfPageFormat.a4.landscape,
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
          pw.SizedBox(height: 4),
          pw.Text(
            'Promedio individual: máximo 25 puntos. '
            'Puntaje total: máximo $maximumScore puntos '
            '($maximumCriteria criterios activos, 25 puntos cada uno).',
            style: const pw.TextStyle(fontSize: 9),
          ),
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
                'Promedio / 25',
                'Criterios calificados',
                'Total / $maximumScore',
              ],
              data: evaluations.map(
                (row) {
                  final count = scoredCriteria(row);
                  return [
                    '${row['dancer_name'] ?? ''}',
                    '${row['career'] ?? ''}',
                    '${row['shift'] ?? ''}',
                    '${row['dance_style'] ?? ''}',
                    '${formatScore(row['average_score'])} / 25',
                    '$count / $maximumCriteria',
                    '${formatScore(row['total_score'])} / $maximumScore',
                  ];
                },
              ).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE5F0EB),
              ),
              cellAlignment: pw.Alignment.center,
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 7,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(0.8),
                3: const pw.FlexColumnWidth(1.3),
                4: const pw.FlexColumnWidth(1.1),
                5: const pw.FlexColumnWidth(1.0),
                6: const pw.FlexColumnWidth(1.1),
              },
            ),
          pw.SizedBox(height: 22),
          pw.Text(
            'Resultados por criterio',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 9),
          if (criteria.isEmpty)
            pw.Text('No hay criterios activos para mostrar.')
          else
            pw.TableHelper.fromTextArray(
              headers: const [
                'Criterio',
                'Nota promedio / 25',
                'Notas registradas',
              ],
              data: criteria
                  .map(
                    (row) => [
                      '${row['criterion_name'] ?? ''}',
                      '${formatScore(row['average_score'])} / 25',
                      '${row['score_count'] ?? 0}',
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE5F0EB),
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 6,
              ),
            ),
        ],
      ),
    );

    if (evaluations.isNotEmpty) {
      pw.Widget signatureCard(Map<String, Object?> row) {
        final participant = '${row['dancer_name'] ?? ''}'.trim();
        final danceTitle = '${row['dance_style'] ?? ''}'.trim();
        final evaluator = '${row['evaluator_name'] ?? ''}'.trim();
        final position = '${row['evaluator_position'] ?? ''}'.trim();

        return pw.Container(
          padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(
              color: const PdfColor.fromInt(0xFFD8DED9),
              width: 0.7,
            ),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                participant.isEmpty ? 'Participante sin nombre' : participant,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (danceTitle.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  danceTitle,
                  style:
                      const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ],
              pw.SizedBox(height: 16),
              pw.Container(
                height: 20,
                alignment: pw.Alignment.bottomCenter,
                child: pw.Text(
                  evaluationSignature(row),
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Container(height: 0.8, color: PdfColors.black),
              pw.SizedBox(height: 5),
              pw.Text(
                evaluator.isEmpty ? 'Docente' : evaluator,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (position.isNotEmpty)
                pw.Text(
                  position,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
            ],
          ),
        );
      }

      document.addPage(
        pw.MultiPage(
          margin: const pw.EdgeInsets.all(32),
          pageFormat: PdfPageFormat.a4.landscape,
          build: (context) => [
            pw.Text(
              'Firmas de las evaluaciones',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#176B58'),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Una línea de firma por evaluación. '
              'El nombre escrito en el formulario se muestra sobre la línea.',
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 16),
            pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(1),
              },
              children: [
                for (var index = 0; index < evaluations.length; index += 2)
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(right: 8, bottom: 12),
                        child: signatureCard(evaluations[index]),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(left: 8, bottom: 12),
                        child: index + 1 < evaluations.length
                            ? signatureCard(evaluations[index + 1])
                            : pw.SizedBox(),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (_) async => document.save());
  }

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox.shrink();

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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No se pudieron cargar datos desde XAMPP. ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final evaluations = snapshot.data![0];
        final criteria = snapshot.data![1];
        /* ESTRUCTURA DE CONSULTAS: primero promedios por criterio y luego evaluaciones. */
        return ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Consultas',
                    style: ScreenDesign.pageTitle,
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
              style: ScreenDesign.supportingText,
            ),
            const SizedBox(height: 22),
            const Text(
              'PROMEDIO POR CRITERIO',
              style: ScreenDesign.sectionTitle,
            ),
            const SizedBox(height: 9),
            if (criteria.isEmpty)
              const _EmptyState(message: 'Aún no hay criterios disponibles.')
            else
              ...criteria.map((row) {
                final average =
                    num.tryParse('${row['average_score']}')?.toDouble() ?? 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                                child: Text(row['criterion_name'] as String)),
                            Text(
                              '${average.toStringAsFixed(1)} / 25',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: average / 25,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(5),
                          backgroundColor: ScreenDesign.progressBackground,
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
              const _EmptyState(
                  message: 'Guarda una evaluación para ver resultados.')
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
        child: Text(message, style: ScreenDesign.supportingText),
      ),
    );
  }
}
