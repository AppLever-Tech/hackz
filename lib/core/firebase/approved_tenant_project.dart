import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Control Plane catalog entry for an approved tenant Firebase project.
///
/// Client SDK fields are registered by Hackz Admin only. Colleges never supply
/// these values at login or in user-facing flows.
class ApprovedTenantProject {
  const ApprovedTenantProject({
    required this.projectId,
    required this.label,
    required this.apiKey,
    required this.appIdWeb,
    required this.appIdAndroid,
    required this.messagingSenderId,
    required this.storageBucket,
    required this.authDomain,
    this.createdAt,
  });

  final String projectId;
  final String label;
  final String apiKey;
  final String appIdWeb;
  final String appIdAndroid;
  final String messagingSenderId;
  final String storageBucket;
  final String authDomain;
  final DateTime? createdAt;

  String get subtitle => 'Approved workspace for Hackz organisations.';

  FirebaseOptions get optionsForCurrentPlatform {
    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: apiKey,
        appId: appIdWeb,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket,
        authDomain: authDomain.isEmpty ? '$projectId.firebaseapp.com' : authDomain,
      );
    }
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appIdAndroid.isNotEmpty ? appIdAndroid : appIdWeb,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: storageBucket,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'projectId': projectId,
      'label': label,
      'apiKey': apiKey,
      'appIdWeb': appIdWeb,
      'appIdAndroid': appIdAndroid,
      'messagingSenderId': messagingSenderId,
      'storageBucket': storageBucket,
      'authDomain': authDomain,
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
    };
  }

  factory ApprovedTenantProject.fromMap(String projectId, Map<String, dynamic> map) {
    return ApprovedTenantProject(
      projectId: (map['projectId'] as String? ?? projectId).trim(),
      label: (map['label'] as String? ?? '').trim(),
      apiKey: (map['apiKey'] as String? ?? '').trim(),
      appIdWeb: (map['appIdWeb'] as String? ?? '').trim(),
      appIdAndroid: (map['appIdAndroid'] as String? ?? '').trim(),
      messagingSenderId: (map['messagingSenderId'] as String? ?? '').trim(),
      storageBucket: (map['storageBucket'] as String? ?? '').trim(),
      authDomain: (map['authDomain'] as String? ?? '').trim(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory ApprovedTenantProject.fromFirebaseOptions({
    required FirebaseOptions options,
    required String label,
  }) {
    return ApprovedTenantProject(
      projectId: options.projectId,
      label: label,
      apiKey: options.apiKey,
      appIdWeb: kIsWeb ? options.appId : '',
      appIdAndroid: !kIsWeb ? options.appId : '',
      messagingSenderId: options.messagingSenderId,
      storageBucket: options.storageBucket ?? '',
      authDomain: options.authDomain ?? '',
      createdAt: DateTime.now().toUtc(),
    );
  }
}
