import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/core/firebase/approved_tenant_project.dart';
import 'package:hackz/core/firebase/tenant_connection_exception.dart';
import 'package:hackz/core/firebase/tenant_firebase.dart';
import 'package:hackz/core/firebase/tenant_resolver.dart';

void main() {
  test('TenantConnectionException uses a user-facing message per failure', () {
    expect(
      const TenantConnectionException(TenantConnectionFailure.invalidCode).message,
      'That organisation code is not valid.',
    );
    expect(
      const TenantConnectionException(TenantConnectionFailure.notFound).message,
      'No organisation was found for that code.',
    );
    expect(
      const TenantConnectionException(TenantConnectionFailure.inactive).message,
      'This organisation is not active yet.',
    );
    expect(
      const TenantConnectionException(TenantConnectionFailure.unapproved).message,
      'This organisation’s workspace is not approved.',
    );
    expect(
      const TenantConnectionException(TenantConnectionFailure.unavailable).message,
      'The organisation workspace is unavailable right now. Try again.',
    );
    expect(
      const TenantConnectionException(TenantConnectionFailure.conflict).message,
      'This organisation code cannot be used. Contact Hackz support.',
    );
  });

  test('invalid organisation codes fail before any Firebase lookup', () async {
    await expectLater(
      TenantResolver.resolveByOrganisationCode('not-a-code'),
      throwsA(
        isA<TenantConnectionException>().having(
          (TenantConnectionException e) => e.failure,
          'failure',
          TenantConnectionFailure.invalidCode,
        ),
      ),
    );
  });

  test('named tenant apps are isolated from the Control Plane app', () {
    expect(
      TenantFirebase.appNameFor(
        tenantId: 'alpha',
        projectId: 'hackz-a17b6',
        controlPlaneProjectId: 'hackz-a17b6',
      ),
      defaultFirebaseAppName,
    );
    expect(
      TenantFirebase.appNameFor(
        tenantId: 'alpha',
        projectId: 'college-one',
        controlPlaneProjectId: 'hackz-a17b6',
      ),
      'tenant-alpha',
    );
    expect(
      TenantFirebase.appNameFor(
        tenantId: 'beta',
        projectId: 'college-two',
        controlPlaneProjectId: 'hackz-a17b6',
      ),
      'tenant-beta',
    );
  });

  test('ApprovedTenantProject maps catalog fields to platform options', () {
    final ApprovedTenantProject project = ApprovedTenantProject.fromMap(
      'college-one',
      <String, dynamic>{
        'label': 'College One',
        'apiKey': 'key-1',
        'appIdWeb': '1:1:web:abc',
        'appIdAndroid': '1:1:android:def',
        'messagingSenderId': '111',
        'storageBucket': 'college-one.appspot.com',
        'authDomain': 'college-one.firebaseapp.com',
      },
    );
    expect(project.projectId, 'college-one');
    expect(project.label, 'College One');
    final FirebaseOptions options = project.optionsForCurrentPlatform;
    expect(options.projectId, 'college-one');
    expect(options.apiKey, 'key-1');
    expect(options.messagingSenderId, '111');
    expect(options.storageBucket, 'college-one.appspot.com');
    expect(options.appId, anyOf('1:1:android:def', '1:1:web:abc'));
  });

  test('Storage is ready when the approved workspace has a bucket', () {
    expect(TenantFirebase.storageBucketConfigured('hackz-a17b6.firebasestorage.app'), isTrue);
    expect(TenantFirebase.storageBucketConfigured('gs://hackz-a17b6.appspot.com'), isTrue);
    expect(TenantFirebase.storageBucketConfigured(''), isFalse);
    expect(TenantFirebase.storageBucketConfigured('gs://'), isFalse);
    expect(TenantFirebase.storageBucketConfigured(null), isFalse);
  });
}
