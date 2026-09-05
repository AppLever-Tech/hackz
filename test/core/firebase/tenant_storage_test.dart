import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';
import 'package:hackz/core/firebase/tenant_connection_exception.dart';
import 'package:hackz/core/firebase/tenant_context.dart';
import 'package:hackz/core/firebase/tenant_resolver.dart';
import 'package:hackz/features/attachment/models/attachment_model.dart';
import 'package:hackz/features/attachment/services/attachment_service.dart';

void main() {
  const FirebaseOptions options = FirebaseOptions(
    apiKey: 'test-key',
    appId: '1:1:web:test',
    messagingSenderId: '1',
    projectId: 'college-one',
    storageBucket: 'college-one.appspot.com',
  );

  test('Control Plane context is not an organisation workspace', () {
    final TenantContext plane = TenantResolver.controlPlane(options);
    expect(plane.tenantId, TenantContext.controlPlaneTenantId);
    expect(plane.isOrganisationWorkspace, isFalse);
  });

  test('organisation workspace is identified by tenant id, not organisation code', () {
    const TenantContext setup = TenantContext(
      tenantId: 'tenant-a',
      organisationCode: '',
      organisationName: 'College A',
      firebaseAppName: 'tenant-a',
      firebaseOptions: options,
      organisationId: 'org-a',
    );
    expect(setup.isOrganisationWorkspace, isTrue);
    expect(setup.organisationCode, isEmpty);
  });

  test('organisation Storage is refused while current is the Control Plane', () {
    expect(
      HackzFirebase.assertOrganisationStorage,
      throwsA(
        isA<StateError>().having(
          (StateError e) => e.message,
          'message',
          contains('tenant Firebase Storage'),
        ),
      ),
    );
  });

  test('workspace lookup rejects an empty tenant id before Firebase', () async {
    await expectLater(
      TenantResolver.workspaceByTenantId(''),
      throwsA(
        isA<TenantConnectionException>().having(
          (TenantConnectionException e) => e.failure,
          'failure',
          TenantConnectionFailure.notFound,
        ),
      ),
    );
  });

  test('organisation Storage paths are unchanged', () {
    expect(
      AttachmentService.folderForEntity(
        entityType: AttachmentEntityType.organization,
        orgId: 'org-1',
        entityId: 'org-1',
      ),
      'orgs/org-1/logos',
    );
    expect(
      AttachmentService.folderForEntity(
        entityType: AttachmentEntityType.problem,
        orgId: 'org-1',
        entityId: 'prob-1',
      ),
      'problems/prob-1',
    );
    expect(
      AttachmentService.folderForEntity(
        entityType: AttachmentEntityType.idea,
        orgId: 'org-1',
        entityId: 'idea-1',
      ),
      'ideas/idea-1',
    );
    expect(
      AttachmentService.folderForEntity(
        entityType: AttachmentEntityType.payment,
        orgId: 'org-1',
        entityId: 'pay-1',
      ),
      'payments/pay-1',
    );
    expect(
      AttachmentService.folderForEntity(
        entityType: AttachmentEntityType.feedback,
        orgId: 'org-1',
        entityId: 'fb-1',
      ),
      'feedback/fb-1',
    );
  });
}
