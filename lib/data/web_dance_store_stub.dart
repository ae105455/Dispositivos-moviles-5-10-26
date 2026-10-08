const bool isWeb = false;

class WebDanceStore {
  Future<List<Map<String, Object?>>> getEvaluators() async =>
      throw UnsupportedError('Browser storage is only available on web.');

  Future<List<Map<String, Object?>>> getDanceStyles() async =>
      throw UnsupportedError('Browser storage is only available on web.');

  Future<List<Map<String, Object?>>> getCriteria() async =>
      throw UnsupportedError('Browser storage is only available on web.');

  Future<Map<String, Object?>> getDashboardSummary() async =>
      throw UnsupportedError('Browser storage is only available on web.');

  Future<List<Map<String, Object?>>> getEvaluationSummaries() async =>
      throw UnsupportedError('Browser storage is only available on web.');

  Future<List<Map<String, Object?>>> getCriterionPerformance() async =>
      throw UnsupportedError('Browser storage is only available on web.');

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
    throw UnsupportedError('Browser storage is only available on web.');
  }
}
