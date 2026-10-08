import 'dart:convert';

import 'package:web/web.dart' as web;

const bool isWeb = true;

class WebDanceStore {
  static const _storageKey = 'pulso_dance_evaluations';
  static const _criteria = [
    'Técnica',
    'Expresión y arte',
    'Coreografía',
    'Vestuario y puesta en escena',
  ];
  static const _styles = ['Salsa', 'Bachata', 'Folklore', 'Contemporáneo'];

  List<Map<String, Object?>> _readEvaluations() {
    final stored = web.window.localStorage.getItem(_storageKey);
    if (stored == null) return [];
    final decoded = jsonDecode(stored);
    if (decoded is! List) {
      throw const FormatException('Invalid saved dance evaluations.');
    }
    return decoded.map((entry) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException('Invalid saved dance evaluation.');
      }
      return Map<String, Object?>.from(entry);
    }).toList();
  }

  Future<List<Map<String, Object?>>> getEvaluators() async => [
    {'id': 1, 'full_name': 'Jurado principal', 'position': ''},
    {'id': 2, 'full_name': 'Jurado invitado', 'position': ''},
  ];

  Future<List<Map<String, Object?>>> getDanceStyles() async => [
    for (var i = 0; i < _styles.length; i++) {'id': i + 1, 'name': _styles[i]},
  ];

  Future<List<Map<String, Object?>>> getCriteria() async => [
    for (var i = 0; i < _criteria.length; i++)
      {'id': i + 1, 'name': _criteria[i], 'weight': 1.0, 'is_active': 1},
  ];

  Future<Map<String, Object?>> getDashboardSummary() async {
    final evaluations = _readEvaluations();
    final averages = evaluations.map(_averageScore).toList();
    return {
      'evaluation_count': evaluations.length,
      'dancer_count': evaluations
          .map(
            (row) =>
                '${row['dancer_name']}|${row['career']}|${row['shift']}',
          )
          .toSet()
          .length,
      'overall_average': averages.isEmpty
          ? 0
          : (averages.reduce((sum, score) => sum + score) / averages.length)
                .roundToDouble(),
    };
  }

  Future<List<Map<String, Object?>>> getEvaluationSummaries() async {
    final evaluations = _readEvaluations();
    return evaluations.reversed.map((row) {
      return <String, Object?>{
        'evaluation_id': row['evaluation_id'],
        'dancer_name': row['dancer_name'],
        'career': row['career'],
        'shift': row['shift'],
        'dance_style': row['dance_style'],
        'evaluator_name': row['evaluator_name'],
        'evaluator_position': row['evaluator_position'],
        'signature': row['signature'],
        'evaluated_at': row['evaluated_at'],
        'notes': row['notes'],
        'average_score': _averageScore(row),
        'scored_criteria': (row['scores'] as List).length,
      };
    }).toList();
  }

  Future<List<Map<String, Object?>>> getCriterionPerformance() async {
    final evaluations = _readEvaluations();
    return [
      for (var i = 0; i < _criteria.length; i++)
        _criterionSummary(evaluations, i + 1, _criteria[i]),
    ];
  }

  Map<String, Object?> _criterionSummary(
    List<Map<String, Object?>> evaluations,
    int criterionId,
    String criterionName,
  ) {
    final scores = <num>[];
    for (final evaluation in evaluations) {
      final entries = evaluation['scores'] as List;
      for (final entry in entries) {
        if (entry is Map<String, dynamic> && entry['criterion_id'] == criterionId) {
          scores.add(entry['score'] as num);
        }
      }
    }
    return {
      'criterion_id': criterionId,
      'criterion_name': criterionName,
      'weight': 1.0,
      'score_count': scores.length,
      'average_score': scores.isEmpty
          ? 0
          : (scores.reduce((sum, score) => sum + score) / scores.length)
                .roundToDouble(),
    };
  }

  double _averageScore(Map<String, Object?> evaluation) {
    final scores = evaluation['scores'] as List;
    if (scores.isEmpty) return 0;
    final total = scores.fold<num>(
      0,
      (sum, entry) {
        final score = (entry as Map<String, dynamic>)['score'];
        if (score is! num) {
          throw const FormatException('Invalid saved dance score.');
        }
        return sum + score;
      },
    );
    return (total / scores.length).roundToDouble();
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
  }) async {
    final evaluations = _readEvaluations();
    evaluations.add({
      'evaluation_id': DateTime.now().microsecondsSinceEpoch,
      'dancer_name': dancerName.trim(),
      'career': career,
      'shift': shift,
      'evaluator_name': evaluatorName.trim(),
      'evaluator_position': evaluatorPosition.trim(),
      'dance_title': danceTitle.trim(),
      'dance_style': danceTitle.trim(),
      'signature': signature.trim(),
      'notes': notes.trim(),
      'evaluated_at': DateTime.now().toIso8601String(),
      'scores': [
        for (final score in scores.entries)
          {'criterion_id': score.key, 'score': score.value},
      ],
    });
    web.window.localStorage.setItem(_storageKey, jsonEncode(evaluations));
  }
}
