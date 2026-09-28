import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/core/branding/hackz_brand_loading_indicator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HackzBrandLoadingIndicator builds and loads layers', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HackzBrandLoadingIndicator(size: 48),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(HackzBrandLoadingIndicator), findsOneWidget);
  });
}
