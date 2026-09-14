import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../utils/firestore_utils.dart';
import '../constants/app_metadata_keys.dart';
import '../models/app_metadata_document.dart';
import '../seed/default_metadata_seed.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';

/// App metadata in `hkzAppMetadata` — Control Plane for SysAdmin edits; tenant
/// project gets the same bundled defaults on first organisation login so About /
/// Terms menus work without a SysAdmin visit.
abstract final class AppMetadataService {
  AppMetadataService._();

  static FirebaseFirestore get _db =>
      HackzFirebase.isOrganisationWorkspace
          ? HackzFirebase.current.firestore
          : HackzFirebase.controlPlane.firestore;

  static final Set<String> _seedCheckedProjectIds = <String>{};
  static final Map<String, Future<void>> _seedInFlightByProject = <String, Future<void>>{};

  static CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(FirestoreUtils.hkzAppMetadata);

  /// Seeds bundled defaults from `assets/default_metadata/*.json` when docs are
  /// missing. Safe to call repeatedly; intended to run after SysAdmin auth
  /// (same timing idea as org-settings bootstrap), not at cold start.
  static String get _projectKey {
    final String projectId = _db.app.options.projectId.trim();
    return projectId.isEmpty ? _db.app.name : projectId;
  }

  static Future<void> ensureSeeded() async {
    final String projectKey = _projectKey;
    if (_seedCheckedProjectIds.contains(projectKey)) return;
    final Future<void>? inFlight = _seedInFlightByProject[projectKey];
    if (inFlight != null) return inFlight;
    final Future<void> task = _seedIfNeeded(projectKey);
    _seedInFlightByProject[projectKey] = task;
    try {
      await task;
    } finally {
      _seedInFlightByProject.remove(projectKey);
    }
  }

  static Future<void> _seedIfNeeded(String projectKey) async {
    try {
      final List<String> missing = <String>[];
      for (final String docId in AppMetadataKeys.all) {
        final DocumentSnapshot<Map<String, dynamic>> snap =
            await _collection.doc(docId).get();
        if (!snap.exists) missing.add(docId);
      }

      if (missing.isEmpty) {
        _seedCheckedProjectIds.add(projectKey);
        return;
      }

      final WriteBatch batch = _db.batch();
      for (final String docId in missing) {
        final Map<String, dynamic> payload = await DefaultMetadataSeed.firestorePayloadFor(docId);
        if (payload.isEmpty) continue;
        batch.set(_collection.doc(docId), payload);
      }
      await batch.commit();
      _seedCheckedProjectIds.add(projectKey);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AppMetadataService.ensureSeeded failed: $e');
      }
    }
  }

  static Future<AppMetadataDocument?> fetch(String docId) async {
    final String id = docId.trim();
    if (id.isEmpty) return null;
    await ensureSeeded();
    final DocumentSnapshot<Map<String, dynamic>> snap = await _collection.doc(id).get();
    if (!snap.exists || snap.data() == null) return null;
    return AppMetadataDocument.fromFirestore(snap.id, snap.data()!);
  }

  static Future<List<AppMetadataDocument>> fetchAll() async {
    await ensureSeeded();
    final QuerySnapshot<Map<String, dynamic>> snap = await _collection.get();
    final List<AppMetadataDocument> docs = snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
            AppMetadataDocument.fromFirestore(doc.id, doc.data()))
        .toList(growable: false);
    docs.sort((AppMetadataDocument a, AppMetadataDocument b) {
      final int ai = AppMetadataKeys.all.indexOf(a.id);
      final int bi = AppMetadataKeys.all.indexOf(b.id);
      return ai.compareTo(bi);
    });
    return docs;
  }

  static Future<void> save(AppMetadataDocument document) async {
    final String id = document.id.trim();
    if (id.isEmpty) return;
    await _collection.doc(id).set(<String, dynamic>{
      ...document.toFirestore(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
