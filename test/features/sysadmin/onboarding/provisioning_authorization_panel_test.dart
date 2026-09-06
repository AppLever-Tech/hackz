import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/core/firebase/tenant_record.dart';
import 'package:hackz/features/sysadmin/onboarding/widgets/provisioning_authorization_panel.dart';

void main() {
  testWidgets('authorized status shows the college grant message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProvisioningAuthorizationPanel(
            status: ProvisioningAuthorizationStatus.verified,
          ),
        ),
      ),
    );

    expect(find.text('Provisioning Authorization'), findsOneWidget);
    expect(find.text('Authorized'), findsOneWidget);
    expect(
      find.text('Hackz provisioning access is authorized by this organisation.'),
      findsOneWidget,
    );
    expect(find.text('Validate Again'), findsNothing);
  });

  testWidgets('revoked status explains re-authorization and offers Validate Again', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProvisioningAuthorizationPanel(
            status: ProvisioningAuthorizationStatus.revoked,
            onValidateAgain: () {},
          ),
        ),
      ),
    );

    expect(find.text('Revoked'), findsOneWidget);
    expect(
      find.text(
        'Provisioning access has been revoked by the organisation. Re-authorization is required for future privileged provisioning.',
      ),
      findsOneWidget,
    );
    expect(find.text('Validate Again'), findsOneWidget);
  });

  testWidgets('pending status is the default lifecycle label', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProvisioningAuthorizationPanel(
            status: ProvisioningAuthorizationStatus.required,
          ),
        ),
      ),
    );

    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('This organisation has not authorized Hackz provisioning yet.'), findsOneWidget);
  });
}
