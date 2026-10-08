import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class DanceDatabase {
  static const _databaseName = 'pulso_dance.db';
  static const _databaseVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final databasePath = await getDatabasesPath();
    _database = await openDatabase(
      path.join(databasePath, _databaseName),
      version: _databaseVersion,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createSchema,
    );
    return _database!;
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE dancers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL COLLATE NOCASE,
        category TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(full_name, category)
      )
    ''');
    await db.execute('''
      CREATE TABLE evaluators (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL UNIQUE COLLATE NOCASE
      )
    ''');
    await db.execute('''
      CREATE TABLE dance_styles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE COLLATE NOCASE
      )
    ''');
    await db.execute('''
      CREATE TABLE criteria (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE COLLATE NOCASE,
        weight REAL NOT NULL DEFAULT 1 CHECK(weight > 0)
      )
    ''');
    await db.execute('''
      CREATE TABLE evaluations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dancer_id INTEGER NOT NULL REFERENCES dancers(id),
        evaluator_id INTEGER NOT NULL REFERENCES evaluators(id),
        dance_style_id INTEGER NOT NULL REFERENCES dance_styles(id),
        evaluated_at TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE scores (
        evaluation_id INTEGER NOT NULL REFERENCES evaluations(id) ON DELETE CASCADE,
        criterion_id INTEGER NOT NULL REFERENCES criteria(id),
        score REAL NOT NULL CHECK(score >= 0 AND score <= 10),
        PRIMARY KEY(evaluation_id, criterion_id)
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_evaluations_date ON evaluations(evaluated_at)',
    );
    await db.execute(
      'CREATE INDEX idx_evaluations_dancer ON evaluations(dancer_id)',
    );

    await db.execute('''
      CREATE VIEW v_evaluation_summary AS
      SELECT e.id AS evaluation_id,
              d.id AS dancer_id,
             d.full_name AS dancer_name,
             d.category AS category,
             s.name AS dance_style,
             u.full_name AS evaluator_name,
             e.evaluated_at AS evaluated_at,
             e.notes AS notes,
             COALESCE(ROUND(AVG(sc.score), 1), 0) AS average_score,
             COUNT(sc.criterion_id) AS scored_criteria
      FROM evaluations e
      JOIN dancers d ON d.id = e.dancer_id
      JOIN dance_styles s ON s.id = e.dance_style_id
      JOIN evaluators u ON u.id = e.evaluator_id
      LEFT JOIN scores sc ON sc.evaluation_id = e.id
      GROUP BY e.id, d.id, d.full_name, d.category, s.name,
               u.full_name, e.evaluated_at, e.notes
    ''');
    await db.execute('''
      CREATE VIEW v_criterion_performance AS
      SELECT c.id AS criterion_id,
             c.name AS criterion_name,
             c.weight AS weight,
             COUNT(sc.evaluation_id) AS score_count,
             COALESCE(ROUND(AVG(sc.score), 1), 0) AS average_score
      FROM criteria c
      LEFT JOIN scores sc ON sc.criterion_id = c.id
      GROUP BY c.id, c.name, c.weight
    ''');

    await db.insert('evaluators', {'full_name': 'Jurado principal'});
    await db.insert('evaluators', {'full_name': 'Jurado invitado'});
    for (final style in ['Salsa', 'Bachata', 'Folklore', 'Contemporáneo']) {
      await db.insert('dance_styles', {'name': style});
    }
    for (final criterion in [
      'Ritmo',
      'Técnica',
      'Expresión',
      'Coordinación',
      'Presencia escénica',
    ]) {
      await db.insert('criteria', {'name': criterion, 'weight': 1.0});
    }
  }

  Future<List<Map<String, Object?>>> getEvaluators() async {
    return (await database).query('evaluators', orderBy: 'full_name');
  }

  Future<List<Map<String, Object?>>> getDanceStyles() async {
    return (await database).query('dance_styles', orderBy: 'name');
  }

  Future<List<Map<String, Object?>>> getCriteria() async {
    return (await database).query('criteria', orderBy: 'id');
  }

  Future<Map<String, Object?>> getDashboardSummary() async {
    final db = await database;
    final totals = await db.rawQuery('''
      SELECT COUNT(*) AS evaluation_count,
              COUNT(DISTINCT dancer_id) AS dancer_count,
             COALESCE(ROUND(AVG(average_score), 1), 0) AS overall_average
      FROM v_evaluation_summary
    ''');
    return totals.first;
  }

  Future<List<Map<String, Object?>>> getEvaluationSummaries() async {
    return (await database).query(
      'v_evaluation_summary',
      orderBy: 'evaluated_at DESC, evaluation_id DESC',
    );
  }

  Future<List<Map<String, Object?>>> getCriterionPerformance() async {
    return (await database).query(
      'v_criterion_performance',
      orderBy: 'average_score DESC, criterion_name',
    );
  }

  Future<void> saveEvaluation({
    required String dancerName,
    required String category,
    required int evaluatorId,
    required int danceStyleId,
    required Map<int, double> scores,
    required String notes,
  }) async {
    final db = await database;
    await db.transaction((transaction) async {
      final existingDancer = await transaction.query(
        'dancers',
        columns: ['id'],
        where: 'full_name = ? AND category = ?',
        whereArgs: [dancerName.trim(), category],
        limit: 1,
      );
      final dancerId = existingDancer.isEmpty
          ? await transaction.insert('dancers', {
              'full_name': dancerName.trim(),
              'category': category,
            })
          : existingDancer.first['id']! as int;

      final evaluationId = await transaction.insert('evaluations', {
        'dancer_id': dancerId,
        'evaluator_id': evaluatorId,
        'dance_style_id': danceStyleId,
        'evaluated_at': DateTime.now().toIso8601String(),
        'notes': notes.trim(),
      });
      for (final score in scores.entries) {
        await transaction.insert('scores', {
          'evaluation_id': evaluationId,
          'criterion_id': score.key,
          'score': score.value,
        });
      }
    });
  }
}