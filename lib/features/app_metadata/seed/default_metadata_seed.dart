import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../constants/app_metadata_keys.dart';
import '../models/app_metadata_document.dart';

/// Loads bundled default metadata JSON from assets.
abstract final class DefaultMetadataSeed {
  DefaultMetadataSeed._();

  static const Map<String, String> _assetByDocId = <String, String>{
    AppMetadataKeys.about: 'assets/default_metadata/about.json',
    AppMetadataKeys.projectTeam: 'assets/default_metadata/project_team.json',
    AppMetadataKeys.privacyPolicy: 'assets/default_metadata/privacy_policy.json',
    AppMetadataKeys.terms: 'assets/default_metadata/terms.json',
    AppMetadataKeys.appInfo: 'assets/default_metadata/app_info.json',
  };

  static Future<List<AppMetadataDocument>> loadAll() async {
    final List<AppMetadataDocument> docs = <AppMetadataDocument>[];
    for (final MapEntry<String, String> entry in _assetByDocId.entries) {
      final String raw = await rootBundle.loadString(entry.value);
      final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
      docs.add(AppMetadataDocument.fromFirestore(entry.key, map));
    }
    return docs;
  }

  static Future<Map<String, dynamic>> firestorePayloadFor(String docId) async {
    final String? asset = _assetByDocId[docId];
    if (asset == null) return <String, dynamic>{};
    final String raw = await rootBundle.loadString(asset);
    final Map<String, dynamic> map = Map<String, dynamic>.from(jsonDecode(raw) as Map<String, dynamic>);
    map['updatedAt'] = FieldValue.serverTimestamp();
    return map;
  }
}
