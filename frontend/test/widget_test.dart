import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('home page opens the account creation route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SamaVetoApp());

    expect(find.text('Sama Veto'), findsWidgets);
    expect(find.text('Commencer maintenant'), findsOneWidget);

    await tester.tap(find.text('Commencer maintenant'));
    await tester.pumpAndSettle();

    expect(find.text('Créer un compte'), findsWidgets);
    expect(
      find.text('La création de compte Sama Veto sera bientôt disponible.'),
      findsOneWidget,
    );
  });

  testWidgets('home page fits a narrow mobile viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SamaVetoApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
