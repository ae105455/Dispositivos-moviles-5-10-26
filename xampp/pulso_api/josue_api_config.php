<?php
// Josue Ramos expone: conexion PDO, respuestas JSON y permisos CORS locales.
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
$origin = $_SERVER['HTTP_ORIGIN'] ?? '';
$localOrigin = preg_match(
    '/^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/i',
    $origin
) === 1;
$configuredOrigin = getenv('PULSO_CORS_ORIGIN') ?: '';
if ($origin !== '' && ($localOrigin || hash_equals($configuredOrigin, $origin))) {
    header('Access-Control-Allow-Origin: ' . $origin);
    header('Vary: Origin');
}
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Access-Control-Max-Age: 600');

if (($_SERVER['REQUEST_METHOD'] ?? '') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function api_response(array $body, int $status = 200): never
{
    http_response_code($status);
    echo json_encode($body, JSON_UNESCAPED_UNICODE | JSON_INVALID_UTF8_SUBSTITUTE);
    exit;
}

function api_success(array $data, int $status = 200): never
{
    api_response(['success' => true, 'data' => $data], $status);
}

function api_error(string $message, int $status = 400): never
{
    api_response(['success' => false, 'error' => $message], $status);
}

function api_db(): PDO
{
    static $pdo = null;
    if ($pdo instanceof PDO) {
        return $pdo;
    }

    $host = getenv('PULSO_DB_HOST') ?: '127.0.0.1';
    $database = getenv('PULSO_DB_NAME') ?: 'pulso_dance';
    $username = getenv('PULSO_DB_USER') ?: 'root';
    $password = getenv('PULSO_DB_PASSWORD') ?: '';
    $pdo = new PDO(
        "mysql:host={$host};dbname={$database};charset=utf8mb4",
        $username,
        $password,
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]
    );
    return $pdo;
}