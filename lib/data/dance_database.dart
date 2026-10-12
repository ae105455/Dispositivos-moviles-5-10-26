import 'abraham_xampp_api_client.dart';

// Abraham integra la app con XAMPP; Josue expone la estructura MySQL/PHP.
class DanceDatabase {
  DanceDatabase({AbrahamXamppApiClient? api})
      : _api = api ?? AbrahamXamppApiClient();

  final AbrahamXamppApiClient _api;

  Future<List<Map<String, Object?>>> getEvaluators() async {
    final data = await _api.getCatalogs();
    return _rows(data['evaluators']);
  }

  Future<List<Map<String, Object?>>> getDanceStyles() async {
    final data = await _api.getCatalogs();
    return _rows(data['dance_styles']);
  }

  Future<List<Map<String, Object?>>> getCriteria() async {
    final data = await _api.getCatalogs();
    return _rows(data['criteria']);
  }

  Future<Map<String, Object?>> getDashboardSummary() async =>
      (await _api.getDashboard())['summary'] as Map<String, Object?>;

  Future<List<Map<String, Object?>>> getEvaluationSummaries() async {
    final data = await _api.getReports();
    return _rows(data['evaluations']);
  }

  Future<List<Map<String, Object?>>> getCriterionPerformance() async {
    final data = await _api.getReports();
    return _rows(data['criteria']);
  }

  Future<void> saveEvaluation({
    required String dancerName,
    required String career,
    required String shift,
    required String evaluatorName,
    required String evaluatorPosition,
    required String danceTitle,
    required String signature,
    required Map<int, double> scores,
    required String notes,
  }) =>
      _api.saveEvaluation({
        'dancer_name': dancerName.trim(),
        'career': career,
        'shift': shift,
        'evaluator_name': evaluatorName.trim(),
        'evaluator_position': evaluatorPosition.trim(),
        'dance_title': danceTitle.trim(),
        'signature': signature.trim(),
        'notes': notes.trim(),
        'scores': [
          for (final score in scores.entries)
            {'criterion_id': score.key, 'score': score.value},
        ],
      });

  List<Map<String, Object?>> _rows(Object? value) => (value as List)
      .map((row) => Map<String, Object?>.from(row as Map))
      .toList();
}
