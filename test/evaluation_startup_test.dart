import 'package:dance_eval_form/data/abraham_xampp_api_client.dart';
import 'package:dance_eval_form/data/dance_database.dart';
import 'package:dance_eval_form/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

void main() {
  testWidgets('opens the evaluation form without waiting for XAMPP', (
    tester,
  ) async {
    var requestCount = 0;
    final api = AbrahamXamppApiClient(
      client: MockClient((_) async {
        requestCount++;
        throw StateError('The app should not request XAMPP on startup.');
      }),
    );

    await tester.pumpWidget(
      MaterialApp(home: DanceShell(database: DanceDatabase(api: api))),
    );
    await tester.pump();

    expect(find.text('Formulario de evaluación de baile'), findsOneWidget);
    expect(find.text('Técnica'), findsOneWidget);
    expect(requestCount, 0);
  });
}
