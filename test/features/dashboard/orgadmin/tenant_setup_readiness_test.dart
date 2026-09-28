import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/dashboard/orgadmin/services/tenant_setup_readiness_service.dart';

void main() {
  group('TenantSetupReadinessLogic', () {
    test('ready when all required checks pass', () {
      const List<TenantSetupCheckItem> items = <TenantSetupCheckItem>[
        TenantSetupCheckItem(label: 'A', done: true),
        TenantSetupCheckItem(label: 'B', done: true, requiredForReady: false),
      ];
      expect(TenantSetupReadinessLogic.isReady(items), isTrue);
    });

    test('not ready when a required check fails', () {
      const List<TenantSetupCheckItem> items = <TenantSetupCheckItem>[
        TenantSetupCheckItem(label: 'A', done: true),
        TenantSetupCheckItem(label: 'B', done: false),
      ];
      expect(TenantSetupReadinessLogic.isReady(items), isFalse);
    });

    test('optional failures do not block ready', () {
      const List<TenantSetupCheckItem> items = <TenantSetupCheckItem>[
        TenantSetupCheckItem(label: 'A', done: true),
        TenantSetupCheckItem(label: 'Teams', done: false, requiredForReady: false),
      ];
      expect(TenantSetupReadinessLogic.isReady(items), isTrue);
    });
  });
}
