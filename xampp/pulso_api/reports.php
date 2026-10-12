<?php
// Josue Ramos expone: consultas para reportes y rendimiento por criterio.
declare(strict_types=1);
require_once __DIR__ . '/josue_api_config.php';

try {
    $pdo = api_db();
    $evaluations = $pdo->query(
        'SELECT evaluation_id, dancer_name, career, shift, dance_style,
                evaluator_name, evaluator_position, signature, evaluated_at,
                notes, total_score, average_score, scored_criteria
         FROM v_evaluation_summary
         ORDER BY evaluated_at DESC, evaluation_id DESC'
    )->fetchAll();
    $criteria = $pdo->query(
        'SELECT criterion_id, criterion_name, weight, score_count, average_score
         FROM v_criterion_performance
         ORDER BY average_score DESC, criterion_name'
    )->fetchAll();
    api_success(['evaluations' => $evaluations, 'criteria' => $criteria]);
} catch (Throwable $error) {
    api_error('No se pudieron leer los reportes: ' . $error->getMessage(), 500);
}