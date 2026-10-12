<?php
// Josue Ramos expone: lectura de catalogos MySQL para el formulario Flutter.
declare(strict_types=1);
require_once __DIR__ . '/josue_api_config.php';

try {
    $pdo = api_db();
    $evaluators = $pdo->query(
        'SELECT id, full_name, position FROM evaluators ORDER BY full_name'
    )->fetchAll();
    $styles = $pdo->query(
        'SELECT id, name FROM dance_styles ORDER BY name'
    )->fetchAll();
    $criteria = $pdo->query(
        'SELECT id, name, weight, is_active FROM criteria WHERE is_active = 1 ORDER BY id'
    )->fetchAll();
    api_success([
        'evaluators' => $evaluators,
        'dance_styles' => $styles,
        'criteria' => $criteria,
    ]);
} catch (Throwable $error) {
    api_error('No se pudieron leer los catalogos: ' . $error->getMessage(), 500);
}