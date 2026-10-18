import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'ipconfig/wifi_api_config.dart';

// Abraham Espinoza Vargas expone: peticiones Flutter hacia la API de XAMPP.
class AbrahamXamppApiClient {
  AbrahamXamppApiClient({http.Client? client})
      : _client = client ?? http.Client();

  static const _configuredBaseUrl = String.fromEnvironment('PULSO_API_URL');

  final http.Client _client;

  static String get baseUrl {
    if (WifiApiConfig.adminBaseUrl case final String adminBaseUrl) {
      return adminBaseUrl;
    }
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      if (WifiApiConfig.useWifiApi) return WifiApiConfig.baseUrl;
      return 'http://10.0.2.2/pulso_api';
    }
    return 'http://localhost/pulso_api';
  }

  String get _baseUrl => baseUrl;

  Future<Map<String, Object?>> getCatalogs() => _get('catalogs.php');

  Future<Map<String, Object?>> getDashboard() => _get('dashboard.php');

  Future<Map<String, Object?>> getReports() => _get('reports.php');

  Future<void> saveEvaluation(Map<String, Object?> evaluation) async {
    await _request('evaluations.php', method: 'POST', body: evaluation);
  }

  Future<Map<String, Object?>> _get(String endpoint) => _request(endpoint);

  Future<Map<String, Object?>> _request(
    String endpoint, {
    String method = 'GET',
    Map<String, Object?>? body,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$endpoint');
      final response = method == 'POST'
          ? await _client
              .post(
                uri,
                headers: const {'Content-Type': 'application/json'},
                body: jsonEncode(body),
              )
              .timeout(const Duration(seconds: 12))
          : await _client.get(uri).timeout(const Duration(seconds: 12));
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('La respuesta de XAMPP no es JSON valido.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            decoded['error'] ?? 'Error HTTP ${response.statusCode}.');
      }
      if (decoded['success'] != true || decoded['data'] is! Map) {
        throw Exception(
            decoded['error'] ?? 'La API devolvio una respuesta invalida.');
      }
      return Map<String, Object?>.from(decoded['data'] as Map);
    } on TimeoutException {
      throw Exception('XAMPP tardo demasiado. Revisa Apache y MySQL.');
    } on http.ClientException {
      throw Exception(
        'No se pudo conectar con XAMPP. Revisa Apache, la URL de la API y CORS.',
      );
    } on FormatException {
      throw Exception(
        'La API no devolvio JSON. Comprueba que Apache encuentre los archivos PHP.',
      );
    }
  }
}
