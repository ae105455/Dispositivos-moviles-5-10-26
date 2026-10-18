import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../data/ipconfig/wifi_api_config.dart';
import '../data/ipconfig/wifi_qr_data.dart';

const _appDownloadUrl =
    'https://github.com/ae105455/Dispositivos-moviles-5-10-26/releases/latest/download/pulso-dance.apk';

class AdminServerScreen extends StatefulWidget {
  const AdminServerScreen({super.key});

  @override
  State<AdminServerScreen> createState() => _AdminServerScreenState();
}

class _AdminServerScreenState extends State<AdminServerScreen> {
  late final TextEditingController _addressController;
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  Timer? _saveTimer;
  Future<void> _saveQueue = Future<void>.value();
  bool _isSaving = false;
  bool _showWifiPassword = false;

  String get _initialAddress {
    final savedUrl = WifiApiConfig.adminBaseUrl ?? WifiApiConfig.baseUrl;
    return Uri.parse(savedUrl).host;
  }

  String? get _qrUrl {
    try {
      return '${WifiApiConfig.normalizeBaseUrl(_addressController.text)}'
          '/catalogs.php';
    } on FormatException {
      return null;
    }
  }

  String? get _wifiQrData => WifiQrData.tryEncode(
        ssid: _ssidController.text,
        password: _passwordController.text,
      );

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: _initialAddress);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _addressController.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onAddressChanged(String value) {
    setState(() {});
    _saveTimer?.cancel();

    try {
      WifiApiConfig.normalizeBaseUrl(value);
    } on FormatException {
      return;
    }

    final address = value.trim();
    _saveTimer = Timer(const Duration(milliseconds: 400), () {
      _saveQueue = _saveQueue.then((_) async {
        if (mounted) setState(() => _isSaving = true);
        try {
          await WifiApiConfig.saveBaseUrl(address);
        } catch (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('No se pudo guardar la IP: $error')),
            );
          }
        } finally {
          if (mounted) setState(() => _isSaving = false);
        }
      });
    });
  }

  void _onWifiChanged(String _) => setState(() {});

  Widget _qrCard({
    required String title,
    required String description,
    required String data,
    required String semanticsLabel,
    String? caption,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(description, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 14),
            Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                color: Colors.white,
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 210,
                  gapless: false,
                  semanticsLabel: semanticsLabel,
                ),
              ),
            ),
            if (caption != null) ...[
              const SizedBox(height: 10),
              SelectableText(
                caption,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrUrl = _qrUrl;
    final wifiQrData = _wifiQrData;

    return Scaffold(
      appBar: AppBar(title: const Text('IP y código QR')),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Text(
            'Escribe la IPv4 de la computadora donde está XAMPP.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _addressController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Dirección IPv4',
              hintText: '192.168.0.30',
              prefixIcon: Icon(Icons.dns_outlined),
            ),
            onChanged: _onAddressChanged,
          ),
          const SizedBox(height: 8),
          Text(
            _isSaving
                ? 'Guardando IP...'
                : 'Ejemplo: 192.168.0.30. Se guarda automáticamente.',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          if (qrUrl case final url?) ...[
            _qrCard(
              title: 'QR para abrir XAMPP',
              description:
                  'Escanéalo para abrir la API del servidor en el navegador.',
              data: url,
              semanticsLabel: 'Código QR para abrir la API de XAMPP',
              caption: url,
            ),
          ] else
            Text(
              'Escribe una IPv4 válida, por ejemplo 192.168.0.30.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 24),
          const Text(
            'QR para conectarse al Wi-Fi',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ingresa el nombre y la contraseña una vez. El QR se genera al instante.',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ssidController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la red Wi-Fi',
              hintText: 'SSID',
              prefixIcon: Icon(Icons.wifi),
            ),
            onChanged: _onWifiChanged,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            obscureText: !_showWifiPassword,
            decoration: InputDecoration(
              labelText: 'Contraseña del Wi-Fi',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _showWifiPassword
                    ? 'Ocultar contraseña'
                    : 'Mostrar contraseña',
                onPressed: () => setState(
                  () => _showWifiPassword = !_showWifiPassword,
                ),
                icon: Icon(
                  _showWifiPassword ? Icons.visibility_off : Icons.visibility,
                ),
              ),
            ),
            onChanged: _onWifiChanged,
          ),
          const SizedBox(height: 8),
          if (wifiQrData == null)
            const Text(
              'El SSID debe tener hasta 32 bytes y la contraseña WPA, '
              'entre 8 y 63 caracteres.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            )
          else ...[
            _qrCard(
              title: 'Conectarse a la red',
              description:
                  'El estudiante escanea este QR con la cámara del celular '
                  'y confirma conectarse.',
              data: wifiQrData,
              semanticsLabel: 'Código QR para conectarse al Wi-Fi',
              caption: 'Red: ${_ssidController.text}',
            ),
            const Text(
              'La contraseña solo se usa en esta pantalla y no se guarda '
              'ni se envía a GitHub.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
          const SizedBox(height: 24),
          _qrCard(
            title: 'Descargar la aplicación',
            description:
                'Escanea para descargar Pulso. El último Release debe incluir '
                'el archivo APK; si no está adjunto, GitHub mostrará 404.',
            data: _appDownloadUrl,
            semanticsLabel: 'Código QR para descargar Pulso desde GitHub',
            caption: 'GitHub Releases · APK Android',
          ),
        ],
      ),
    );
  }
}
