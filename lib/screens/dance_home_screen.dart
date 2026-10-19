import 'package:flutter/material.dart';

import '../data/dance_database.dart';
import '../design/design_styles.dart';

// Abraham Espinoza Vargas expone: pantalla de inicio, resumen y menu visual.

class DanceHomeScreen extends StatelessWidget {
  const DanceHomeScreen({
    super.key,
    required this.database,
    required this.refreshKey,
    required this.active,
    required this.onStartEvaluation,
    required this.onOpenReports,
    required this.onOpenServerConfig,
  });

  final DanceDatabase database;
  final int refreshKey;
  final bool active;
  final VoidCallback onStartEvaluation;
  final VoidCallback onOpenReports;
  final VoidCallback onOpenServerConfig;

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox.shrink();

    return FutureBuilder<Map<String, Object?>>(
      key: ValueKey(refreshKey),
      future: database.getDashboardSummary(),
      builder: (context, snapshot) {
        final totals = snapshot.data ?? const <String, Object?>{};
        /* ESTRUCTURA: bienvenida, resumen y acceso a consultas en una lista vertical. */
        return ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: ScreenDesign.green,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EL MOVIMIENTO\nTAMBIÉN SE MIDE.',
                    style: ScreenDesign.heroTitle,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Registra cada presentación con criterio y ritmo.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.84),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 21),
                  FilledButton.icon(
                    onPressed: onStartEvaluation,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD36B),
                      foregroundColor: ScreenDesign.ink,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Nueva evaluación'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: onOpenServerConfig,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                    ),
                    icon: const Icon(Icons.qr_code_rounded),
                    label: const Text('Cambiar IP y ver QR'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            /* COLUMNAS RESPONSIVAS: el resumen usa tres columnas en pantallas anchas. */
            const _SectionHeading(
                title: 'RESUMEN', detail: 'Datos registrados'),
            const SizedBox(height: 12),
            if (snapshot.hasError)
              Text('No se pudo leer XAMPP: ${snapshot.error}')
            else if (snapshot.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 540 ? 3 : 1;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: columns == 1 ? 3.2 : 1.25,
                    children: [
                      _MetricTile(
                        icon: Icons.assignment_turned_in_outlined,
                        label: 'Evaluaciones',
                        value: '${totals['evaluation_count'] ?? 0}',
                        tint: ScreenDesign.greenTint,
                      ),
                      _MetricTile(
                        icon: Icons.groups_2_outlined,
                        label: 'Bailarines',
                        value: '${totals['dancer_count'] ?? 0}',
                        tint: ScreenDesign.coralTint,
                      ),
                      _MetricTile(
                        icon: Icons.speed_rounded,
                        label: 'Promedio general',
                        value: '${totals['overall_average'] ?? 0}/25',
                        tint: ScreenDesign.yellowTint,
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 25),
            const _SectionHeading(
              title: 'ACCESO RÁPIDO',
              detail: 'Continúa desde aquí',
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE5F0EB),
                child:
                    Icon(Icons.query_stats_rounded, color: Color(0xFF176B58)),
              ),
              title: const Text('Consultar resultados'),
              subtitle: const Text('Promedios por baile y criterio'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: onOpenReports,
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: ScreenDesign.sectionTitle.copyWith(letterSpacing: 1.3),
        ),
        const SizedBox(width: 9),
        Text(
          detail,
          style: const TextStyle(fontSize: 12, color: ScreenDesign.muted),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: tint,
              child: Icon(icon, color: const Color(0xFF202928), size: 20),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: ScreenDesign.metricValue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
