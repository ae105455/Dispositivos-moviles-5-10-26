import 'dart:convert';

class WifiQrData {
  const WifiQrData._();

  static String encode({
    required String ssid,
    required String password,
  }) {
    if (ssid.isEmpty || utf8.encode(ssid).length > 32) {
      throw const FormatException(
        'El nombre de red debe tener entre 1 y 32 bytes UTF-8.',
      );
    }
    if (!RegExp(r'^(?:[\x20-\x7E]{8,63}|[0-9A-Fa-f]{64})$')
        .hasMatch(password)) {
      throw const FormatException(
        'La contraseña WPA debe tener entre 8 y 63 caracteres.',
      );
    }

    return 'WIFI:T:WPA;S:${_escape(ssid)};P:${_escape(password)};;';
  }

  static String? tryEncode({
    required String ssid,
    required String password,
  }) {
    try {
      return encode(ssid: ssid, password: password);
    } on FormatException {
      return null;
    }
  }

  static String _escape(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll('"', r'\"')
        .replaceAll(':', r'\:');
  }
}
