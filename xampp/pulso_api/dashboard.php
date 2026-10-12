<?php
// Josue Ramos expone: resumen calculado desde las evaluaciones MySQL.
declare(strict_types=1);
require_once __DIR__ . '/josue_api_config.php';

try {
    $summary = api_db()->query(
        'SELECT COUNT(*) AS evaluation_count,
                COUNT(DISTINCT dancer_id) AS dancer_count,
                COALESCE(ROUND(AVG(average_score), 1), 0) AS overall_average
         FROM v_evaluation_summary'
    )->fetch();
    api_success(['summary' => $summary]);
} catch (Throwable $error) {
    api_error('No se pudo leer el resumen: ' . $error->getMessage(), 500);
}