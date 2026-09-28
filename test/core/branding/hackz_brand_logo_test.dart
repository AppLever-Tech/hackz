import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/core/branding/hackz_brand_assets.dart';
import 'package:hackz/core/branding/hackz_brand_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('brand asset paths are under assets/branding', () {
    expect(HackzBrandAssets.primaryLogo, startsWith('assets/branding/'));
    expect(HackzBrandAssets.launcherLogo, startsWith('assets/branding/'));
    expect(HackzBrandAssets.symbol, startsWith('assets/branding/'));
    expect(HackzBrandAssets.loadingSymbol, startsWith('assets/branding/'));
  });

  testWidgets('HackzBrandLogo builds for each variant', (WidgetTester tester) async {
    for (final HackzBrandLogoVariant variant in HackzBrandLogoVariant.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HackzBrandLogo(variant: variant, height: 48),
          ),
        ),
      );
      expect(find.byType(HackzBrandLogo), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
