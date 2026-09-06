import 'hackz_firebase.dart';

class ProvisioningIamRole {
  const ProvisioningIamRole({
    required this.role,
    required this.title,
    required this.reason,
  });

  final String role;
  final String title;
  final String reason;
}

class HackzProvisioningIdentity {
  const HackzProvisioningIdentity({
    required this.serviceAccountEmail,
    required this.iamRoles,
  });

  final String serviceAccountEmail;
  final List<ProvisioningIamRole> iamRoles;

  static const String collectionName = 'hkzProvisioningConfig';
  static const String documentId = 'hackz';

  static const List<ProvisioningIamRole> minimumIamRoles = <ProvisioningIamRole>[
    ProvisioningIamRole(
      role: 'roles/firebaseauth.admin',
      title: 'Firebase Authentication Admin',
      reason: 'Create the first College Admin sign-in user. Not Owner or Editor.',
    ),
    ProvisioningIamRole(
      role: 'roles/datastore.user',
      title: 'Cloud Datastore User',
      reason: 'Write the College Admin profile in Firestore. Does not include Cloud Storage.',
    ),
  ];

  static Future<HackzProvisioningIdentity> load() async {
    String email = '';
    try {
      final doc = await HackzFirebase.controlPlane.firestore
          .collection(collectionName)
          .doc(documentId)
          .get();
      email = ((doc.data()?['serviceAccountEmail'] as String?) ?? '').trim();
    } catch (_) {
      email = '';
    }
    if (email.isEmpty) {
      final String projectId = HackzFirebase.controlPlane.context.firebaseOptions.projectId.trim();
      email = 'hackz-provisioning@$projectId.iam.gserviceaccount.com';
    }
    return HackzProvisioningIdentity(serviceAccountEmail: email, iamRoles: minimumIamRoles);
  }
}
