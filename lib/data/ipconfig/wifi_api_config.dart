import 'package:shared_preferences/shared_preferences.dart';

class WifiApiConfig {
  WifiApiConfig._();

  static const bool useWifiApi = true;
  static const String baseUrl = 'http://172.20.10.9/pulso_api';
  static const _apiUrlPreferenceKey = 'pulso_api_base_url_v2';
  static final _preferences = SharedPreferencesAsync();

  static String? _adminBaseUrl;

  static String? get adminBaseUrl => _adminBaseUrl;

  static Future<void> load() async {
    _adminBaseUrl = await _preferences.getString(_apiUrlPreferenceKey);
  }

  static Future<void> saveBaseUrl(String input) async {
    final normalizedUrl = normalizeBaseUrl(input);
    await _preferences.setString(_apiUrlPreferenceKey, normalizedUrl);
    _adminBaseUrl = normalizedUrl;
  }

  static Future<void> resetBaseUrl() async {
    await _preferences.remove(_apiUrlPreferenceKey);
    _adminBaseUrl = null;
  }

  static String normalizeBaseUrl(String input) {
    final address = input.trim();
    if (address.isEmpty) {
      throw const FormatException('Escribe la dirección IPv4 del servidor.');
    }
    final octets = address.split('.');
    if (octets.length != 4 ||
        octets.any(
          (octet) =>
              octet.isEmpty ||
              !RegExp(r'^\d{1,3}$').hasMatch(octet) ||
              int.parse(octet) > 255,
        )) {
      throw const FormatException(
        'Escribe una IPv4 válida, por ejemplo 172.20.10.9.',
      );
    }

    return 'http://$address/pulso_api';
  }

  static String webAppUrl(String input) {
    final apiUri = Uri.parse(normalizeBaseUrl(input));
    return apiUri.replace(path: '/pulso/').toString();
  }

  static String? webApiBaseUrl(Uri appUri) {
    if (!appUri.path.startsWith('/pulso/')) return null;
    return Uri(
      scheme: appUri.scheme,
      userInfo: appUri.userInfo,
      host: appUri.host,
      port: appUri.hasPort ? appUri.port : null,
      path: '/pulso_api',
    ).toString();
  }
}
