import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'web_dance_store_stub.dart'
    if (dart.library.html) 'web_dance_store.dart' as web_store;

class DanceDatabase {
  static const _databaseName = 'pulso_dance.db';
  static const _databaseVersion = 2;

  Database? _database;
  final _webStore = web_store.WebDanceStore();

  Future<Database> get database async {
    if (_database != null) return _database!;
    final databasePath = await getDatabasesPath();
    _database = await openDatabase(
      path.join(databasePath, _databaseName),
      version: _databaseVersion,
      onConfigure: (db) async => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createSchema,
      onUpgrade: _upgradeSchema,
    );
    return _database!;
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE dancers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL COLLATE NOCASE,
        category TEXT NOT NULL,
        career TEXT NOT NULL,
        shift TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(full_name, category)
      )
    ''');
    await db.execute('''
      CREATE TABLE evaluators (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL UNIQUE COLLATE NOCASE,
        position TEXT NOT NULL DEFAULT ''
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
        weight REAL NOT NULL DEFAULT 1 CHECK(weight > 0),
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE evaluations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        dancer_id INTEGER NOT NULL REFERENCES dancers(id),
        evaluator_id INTEGER NOT NULL REFERENCES evaluators(id),
        dance_style_id INTEGER NOT NULL REFERENCES dance_styles(id),
        evaluated_at TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        signature TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE scores (
        evaluation_id INTEGER NOT NULL REFERENCES evaluations(id) ON DELETE CASCADE,
        criterion_id INTEGER NOT NULL REFERENCES criteria(id),
        score REAL NOT NULL CHECK(score >= 0 AND score <= 25),
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
             d.career AS career,
             d.shift AS shift,
             s.name AS dance_style,
             u.full_name AS evaluator_name,
             u.position AS evaluator_position,
             e.signature AS signature,
             e.evaluated_at AS evaluated_at,
             e.notes AS notes,
             COALESCE(ROUND(AVG(sc.score), 1), 0) AS average_score,
             COUNT(sc.criterion_id) AS scored_criteria
      FROM evaluations e
      JOIN dancers d ON d.id = e.dancer_id
      JOIN dance_styles s ON s.id = e.dance_style_id
      JOIN evaluators u ON u.id = e.evaluator_id
      LEFT JOIN scores sc ON sc.evaluation_id = e.id
      GROUP BY e.id, d.id, d.full_name, d.career, d.shift, s.name,
               u.full_name, u.position, e.signature, e.evaluated_at, e.notes
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
      WHERE c.is_active = 1
      GROUP BY c.id, c.name, c.weight
    ''');

    await db.insert('evaluators', {
      'full_name': 'Jurado principal',
      'position': '',
    });
    await db.insert('evaluators', {
      'full_name': 'Jurado invitado',
      'position': '',
    });
    for (final style in ['Salsa', 'Bachata', 'Folklore', 'Contemporáneo']) {
      await db.insert('dance_styles', {'name': style});
    }
    for (final criterion in [
      'Técnica',
      'Expresión y arte',
      'Coreografía',
      'Vestuario y puesta en escena',
    ]) {
      await db.insert('criteria', {
        'name': criterion,
        'weight': 1.0,
        'is_active': 1,
      });
    }
  }

  Future<void> _upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('DROP VIEW IF EXISTS v_evaluation_summary');
      await db.execute('DROP VIEW IF EXISTS v_criterion_performance');
      await db.execute(
        "ALTER TABLE dancers ADD COLUMN career TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE dancers ADD COLUMN shift TEXT NOT NULL DEFAULT 'Mañana'",
      );
      await db.execute('UPDATE dancers SET career = category');
      await db.execute(
        "ALTER TABLE evaluators ADD COLUMN position TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        "ALTER TABLE evaluations ADD COLUMN signature TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        'ALTER TABLE criteria ADD COLUMN is_active INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('ALTER TABLE scores RENAME TO scores_legacy');
      await db.execute('''
        CREATE TABLE scores (
          evaluation_id INTEGER NOT NULL REFERENCES evaluations(id) ON DELETE CASCADE,
          criterion_id INTEGER NOT NULL REFERENCES criteria(id),
          score REAL NOT NULL CHECK(score >= 0 AND score <= 25),
          PRIMARY KEY(evaluation_id, criterion_id)
        )
      ''');
      await db.execute('''
        INSERT INTO scores (evaluation_id, criterion_id, score)
        SELECT evaluation_id, criterion_id, score * 2.5 FROM scores_legacy
      ''');
      await db.execute('DROP TABLE scores_legacy');
      await db.execute('UPDATE criteria SET is_active = 0');
      for (final criterion in [
        'Técnica',
        'Expresión y arte',
        'Coreografía',
        'Vestuario y puesta en escena',
      ]) {
        final existing = await db.query(
          'criteria',
          columns: ['id'],
          where: 'name = ?',
          whereArgs: [criterion],
          limit: 1,
        );
        if (existing.isEmpty) {
          await db.insert('criteria', {
            'name': criterion,
            'weight': 1.0,
            'is_active': 1,
          });
        } else {
          await db.update(
            'criteria',
            {'weight': 1.0, 'is_active': 1},
            where: 'id = ?',
            whereArgs: [existing.first['id']],
          );
        }
      }
      await _createViews(db);
    }
  }

  Future<void> _createViews(Database db) async {
    await db.execute('''
      CREATE VIEW v_evaluation_summary AS
      SELECT e.id AS evaluation_id,
             d.id AS dancer_id,
             d.full_name AS dancer_name,
             d.career AS career,
             d.shift AS shift,
             s.name AS dance_style,
             u.full_name AS evaluator_name,
             u.position AS evaluator_position,
             e.signature AS signature,
             e.evaluated_at AS evaluated_at,
             e.notes AS notes,
             COALESCE(ROUND(AVG(sc.score), 1), 0) AS average_score,
             COUNT(sc.criterion_id) AS scored_criteria
      FROM evaluations e
      JOIN dancers d ON d.id = e.dancer_id
      JOIN dance_styles s ON s.id = e.dance_style_id
      JOIN evaluators u ON u.id = e.evaluator_id
      LEFT JOIN scores sc ON sc.evaluation_id = e.id
      GROUP BY e.id, d.id, d.full_name, d.career, d.shift, s.name,
               u.full_name, u.position, e.signature, e.evaluated_at, e.notes
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
      WHERE c.is_active = 1
      GROUP BY c.id, c.name, c.weight
    ''');
  }

  Future<List<Map<String, Object?>>> getEvaluators() async {
    if (web_store.isWeb) return _webStore.getEvaluators();
    return (await database).query('evaluators', orderBy: 'full_name');
  }

  Future<List<Map<String, Object?>>> getDanceStyles() async {
    if (web_store.isWeb) return _webStore.getDanceStyles();
    return (await database).query('dance_styles', orderBy: 'name');
  }

  Future<List<Map<String, Object?>>> getCriteria() async {
    if (web_store.isWeb) return _webStore.getCriteria();
    return (await database).query(
      'criteria',
      where: 'is_active = 1',
      orderBy: 'id',
    );
  }

  Future<Map<String, Object?>> getDashboardSummary() async {
    if (web_store.isWeb) return _webStore.getDashboardSummary();
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
    if (web_store.isWeb) return _webStore.getEvaluationSummaries();
    return (await database).query(
      'v_evaluation_summary',
      orderBy: 'evaluated_at DESC, evaluation_id DESC',
    );
  }

  Future<List<Map<String, Object?>>> getCriterionPerformance() async {
    if (web_store.isWeb) return _webStore.getCriterionPerformance();
    return (await database).query(
      'v_criterion_performance',
      orderBy: 'average_score DESC, criterion_name',
    );
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
    if (web_store.isWeb) {
      await _webStore.saveEvaluation(
        dancerName: dancerName,
        career: career,
        shift: shift,
        evaluatorName: evaluatorName,
        evaluatorPosition: evaluatorPosition,
        danceTitle: danceTitle,
        signature: signature,
        scores: scores,
        notes: notes,
      );
      return;
    }
    final db = await database;
    await db.transaction((transaction) async {
      final categoryKey = '$career | $shift';
      final existingDancer = await transaction.query(
        'dancers',
        columns: ['id'],
        where: 'full_name = ? AND category = ?',
        whereArgs: [dancerName.trim(), categoryKey],
        limit: 1,
      );
      final dancerId = existingDancer.isEmpty
          ? await transaction.insert('dancers', {
              'full_name': dancerName.trim(),
              'category': categoryKey,
              'career': career,
              'shift': shift,
            })
          : existingDancer.first['id']! as int;

      final evaluatorRows = await transaction.query(
        'evaluators',
        columns: ['id'],
        where: 'full_name = ?',
        whereArgs: [evaluatorName.trim()],
        limit: 1,
      );
      final evaluatorId = evaluatorRows.isEmpty
          ? await transaction.insert('evaluators', {
              'full_name': evaluatorName.trim(),
              'position': evaluatorPosition.trim(),
            })
          : evaluatorRows.first['id']! as int;
      if (evaluatorRows.isNotEmpty) {
        await transaction.update(
          'evaluators',
          {'position': evaluatorPosition.trim()},
          where: 'id = ?',
          whereArgs: [evaluatorId],
        );
      }
      final styleRows = await transaction.query(
        'dance_styles',
        columns: ['id'],
        where: 'name = ?',
        whereArgs: [danceTitle.trim()],
        limit: 1,
      );
      final danceStyleId = styleRows.isEmpty
          ? await transaction.insert('dance_styles', {'name': danceTitle.trim()})
          : styleRows.first['id']! as int;

      final evaluationId = await transaction.insert('evaluations', {
        'dancer_id': dancerId,
        'evaluator_id': evaluatorId,
        'dance_style_id': danceStyleId,
        'evaluated_at': DateTime.now().toIso8601String(),
        'notes': notes.trim(),
        'signature': signature.trim(),
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