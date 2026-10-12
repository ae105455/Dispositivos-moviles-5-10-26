import 'package:flutter/material.dart';

// Abraham Espinoza Vargas expone: estilos visuales compartidos de la aplicacion.
abstract final class ScreenDesign {
  static const ink = Color(0xFF202928);
  static const green = Color(0xFF176B58);
  static const muted = Color(0xFF6F7772);
  static const greenTint = Color(0xFFE5F0EB);
  static const coralTint = Color(0xFFFFE8DE);
  static const yellowTint = Color(0xFFFFF0C6);
  static const progressBackground = Color(0xFFE9ECE8);

  static const heroTitle = TextStyle(
    color: Colors.white,
    fontSize: 29,
    height: 1.1,
    fontWeight: FontWeight.w900,
  );

  static const pageTitle = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w900,
  );

  static const sectionTitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w900,
  );

  static const supportingText = TextStyle(color: muted);

  static const metricValue = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );
}