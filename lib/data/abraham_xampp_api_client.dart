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
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (kIsWeb) {
      final sameOriginBaseUrl = WifiApiConfig.webApiBaseUrl(Uri.base);
      if (sameOriginBaseUrl != null) return sameOriginBaseUrl;
      if (WifiApiConfig.adminBaseUrl case final String adminBaseUrl) {
        return adminBaseUrl;
      }
      return 'http://localhost/pulso_api';
    }
    if (WifiApiConfig.adminBaseUrl case final String adminBaseUrl) {
      return adminBaseUrl;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
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
      Object? decoded;
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        final contentType =
            response.headers['content-type'] ?? 'no informado';
        throw Exception(
          'La dirección $uri respondió HTTP ${response.statusCode} con '
          'Content-Type "$contentType", no JSON. Verifica la IP guardada '
          'y que XAMPP esté sirviendo pulso_api.',
        );
      }
      if (decoded is! Map<String, dynamic>) {
        throw Exception(
          'La dirección $uri devolvió JSON con un formato inesperado.',
        );
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
    }
  }
}
