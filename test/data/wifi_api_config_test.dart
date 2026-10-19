import 'package:dance_eval_form/data/ipconfig/wifi_api_config.dart';
import 'package:dance_eval_form/data/ipconfig/wifi_qr_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WifiApiConfig.normalizeBaseUrl', () {
    test('creates the API URL from an IPv4 address', () {
      expect(
        WifiApiConfig.normalizeBaseUrl('172.20.10.9'),
        'http://172.20.10.9/pulso_api',
      );
    });

    test('trims whitespace around the IPv4 address', () {
      expect(
        WifiApiConfig.normalizeBaseUrl(' 172.20.10.9 '),
        'http://172.20.10.9/pulso_api',
      );
    });

    test('rejects incomplete, out-of-range, and non-IPv4 input', () {
      for (final address in [
        '',
        '192.168.2',
        '192.168.2.256',
        'http://172.20.10.9',
        '172.20.10.9/pulso_api',
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

  group('WifiApiConfig.webAppUrl', () {
    test('creates the same-origin web app URL from an IPv4 address', () {
      expect(
        WifiApiConfig.webAppUrl('192.168.1.178'),
        'http://192.168.1.178/pulso/',
      );
    });

    test('rejects invalid IPv4 input', () {
      expect(
        () => WifiApiConfig.webAppUrl('192.168.1.256'),
        throwsFormatException,
      );
    });

    test('uses the app host for its API and drops the web route', () {
      expect(
        WifiApiConfig.webApiBaseUrl(
          Uri.parse('http://172.20.10.9/pulso/?from=qr#home'),
        ),
        'http://172.20.10.9/pulso_api',
      );
    });

    test('does not override API settings outside the deployed app path', () {
      expect(
        WifiApiConfig.webApiBaseUrl(
          Uri.parse('http://localhost:5000/'),
        ),
        isNull,
      );
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
