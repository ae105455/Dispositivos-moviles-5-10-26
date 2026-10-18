import 'package:dance_eval_form/data/ipconfig/wifi_api_config.dart';
import 'package:dance_eval_form/data/ipconfig/wifi_qr_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WifiApiConfig.normalizeBaseUrl', () {
    test('creates the API URL from an IPv4 address', () {
      expect(
        WifiApiConfig.normalizeBaseUrl('192.168.0.30'),
        'http://192.168.0.30/pulso_api',
      );
    });

    test('trims whitespace around the IPv4 address', () {
      expect(
        WifiApiConfig.normalizeBaseUrl(' 192.168.0.30 '),
        'http://192.168.0.30/pulso_api',
      );
    });

    test('rejects incomplete, out-of-range, and non-IPv4 input', () {
      for (final address in [
        '',
        '192.168.2',
        '192.168.2.256',
        'http://192.168.0.30',
        '192.168.0.30/pulso_api',
        'example.com',
      ]) {
        expect(
          () => WifiApiConfig.normalizeBaseUrl(address),
          throwsFormatException,
          reason: 'Expected "$address" to be rejected.',
        );
      }
    });
  });

  group('WifiQrData.encode', () {
    test('encodes a Wi-Fi QR with escaped credentials', () {
      expect(
        WifiQrData.encode(
          ssid: 'Dance;Hall',
          password: r'dance;pass:123',
        ),
        r'WIFI:T:WPA;S:Dance\;Hall;P:dance\;pass\:123;;',
      );
    });

    test('rejects a missing SSID and a short Wi-Fi password', () {
      expect(
        () => WifiQrData.encode(ssid: '', password: 'dance-pass-123'),
        throwsFormatException,
      );
      expect(
        () => WifiQrData.encode(ssid: 'Dance Hall', password: 'short'),
        throwsFormatException,
      );
    });
  });
}
