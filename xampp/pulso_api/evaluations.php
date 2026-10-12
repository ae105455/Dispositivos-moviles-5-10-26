<?php
// Josue Ramos expone: validacion y guardado transaccional de evaluaciones.
declare(strict_types=1);
require_once __DIR__ . '/josue_api_config.php';

if (($_SERVER['REQUEST_METHOD'] ?? '') !== 'POST') {
    api_error('Usa POST para guardar una evaluacion.', 405);
}

$input = json_decode(file_get_contents('php://input') ?: '', true);
if (!is_array($input)) {
    api_error('El cuerpo de la solicitud no contiene JSON valido.');
}

$required = [
    'dancer_name', 'career', 'shift', 'evaluator_name',
    'evaluator_position', 'dance_title', 'signature', 'scores',
];
foreach ($required as $field) {
    if (!isset($input[$field]) || (is_string($input[$field]) && trim($input[$field]) === '')) {
        api_error('Falta el campo obligatorio: ' . $field);
    }
}
if (!is_array($input['scores']) || count($input['scores']) === 0) {
    api_error('La evaluacion debe incluir sus puntuaciones.');
}

$scores = [];
foreach ($input['scores'] as $scoreRow) {
    if (!is_array($scoreRow) || !isset($scoreRow['criterion_id'], $scoreRow['score'])) {
        api_error('El formato de una puntuacion no es valido.');
    }
    $criterionId = filter_var($scoreRow['criterion_id'], FILTER_VALIDATE_INT);
    $score = filter_var($scoreRow['score'], FILTER_VALIDATE_FLOAT);
    if ($criterionId === false || $score === false || $score < 0 || $score > 25) {
        api_error('Cada puntuacion debe estar entre 0 y 25.');
    }
    if (isset($scores[$criterionId])) {
        api_error('No repitas el mismo criterio en una evaluacion.');
    }
    $scores[$criterionId] = $score;
}

try {
    $pdo = api_db();
    $activeIds = array_map(
        'intval',
        $pdo->query('SELECT id FROM criteria WHERE is_active = 1 ORDER BY id')->fetchAll(PDO::FETCH_COLUMN)
    );
    $submittedIds = array_map('intval', array_keys($scores));
    sort($activeIds);
    sort($submittedIds);
    if ($activeIds !== $submittedIds) {
        api_error('Las puntuaciones no coinciden con los criterios activos.', 422);
    }

    $pdo->beginTransaction();

    $dancer = $pdo->prepare(
        'INSERT INTO dancers (full_name, category, career, shift)
         VALUES (?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE id = LAST_INSERT_ID(id), career = VALUES(career), shift = VALUES(shift)'
    );
    $dancer->execute([
        trim((string)$input['dancer_name']),
        trim((string)$input['career']) . ' | ' . trim((string)$input['shift']),
        trim((string)$input['career']),
        trim((string)$input['shift']),
    ]);
    $dancerId = (int)$pdo->lastInsertId();

    $evaluator = $pdo->prepare(
        'INSERT INTO evaluators (full_name, position) VALUES (?, ?)
         ON DUPLICATE KEY UPDATE id = LAST_INSERT_ID(id), position = VALUES(position)'
    );
    $evaluator->execute([
        trim((string)$input['evaluator_name']),
        trim((string)$input['evaluator_position']),
    ]);
    $evaluatorId = (int)$pdo->lastInsertId();

    $style = $pdo->prepare(
        'INSERT INTO dance_styles (name) VALUES (?)
         ON DUPLICATE KEY UPDATE id = LAST_INSERT_ID(id)'
    );
    $style->execute([trim((string)$input['dance_title'])]);
    $styleId = (int)$pdo->lastInsertId();

    $evaluation = $pdo->prepare(
        'INSERT INTO evaluations
         (dancer_id, evaluator_id, dance_style_id, evaluated_at, notes, signature)
         VALUES (?, ?, ?, NOW(), ?, ?)'
    );
    $evaluation->execute([
        $dancerId,
        $evaluatorId,
        $styleId,
        trim((string)($input['notes'] ?? '')),
        trim((string)$input['signature']),
    ]);
    $evaluationId = (int)$pdo->lastInsertId();

    $insertScore = $pdo->prepare(
        'INSERT INTO scores (evaluation_id, criterion_id, score) VALUES (?, ?, ?)'
    );
    foreach ($scores as $criterionId => $score) {
        $insertScore->execute([$evaluationId, $criterionId, $score]);
    }

    $pdo->commit();
    api_success(['evaluation_id' => $evaluationId], 201);
} catch (Throwable $error) {
    if (isset($pdo) && $pdo instanceof PDO && $pdo->inTransaction()) {
        $pdo->rollBack();
    }
    api_error('No se pudo guardar en MySQL: ' . $error->getMessage(), 500);
}