import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../utils/firestore_utils.dart';
import '../constants/app_metadata_keys.dart';
import '../models/app_metadata_document.dart';
import '../seed/default_metadata_seed.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';

/// Reads and writes global app metadata in `hkzAppMetadata` on the Control Plane.
/// Organisation tenants never host product About / Terms / Privacy documents.
abstract final class AppMetadataService {
  AppMetadataService._();

  static FirebaseFirestore get _db => HackzFirebase.controlPlane.firestore;
  static bool _seedChecked = false;
  static Future<void>? _seedInFlight;

  static CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(FirestoreUtils.hkzAppMetadata);

  /// Seeds bundled defaults from `assets/default_metadata/*.json` when docs are
  /// missing. Safe to call repeatedly; intended to run after SysAdmin auth
  /// (same timing idea as org-settings bootstrap), not at cold start.
  static Future<void> ensureSeeded() async {
    if (_seedChecked) return;
    if (_seedInFlight != null) return _seedInFlight!;
    _seedInFlight = _seedIfNeeded();
    try {
      await _seedInFlight;
    } finally {
      _seedInFlight = null;
    }
  }

  static Future<void> _seedIfNeeded() async {
    try {
      final List<String> missing = <String>[];
      for (final String docId in AppMetadataKeys.all) {
        final DocumentSnapshot<Map<String, dynamic>> snap =
            await _collection.doc(docId).get();
        if (!snap.exists) missing.add(docId);
      }

      if (missing.isEmpty) {
        _seedChecked = true;
        return;
      }

      final WriteBatch batch = _db.batch();
      for (final String docId in missing) {
        final Map<String, dynamic> payload = await DefaultMetadataSeed.firestorePayloadFor(docId);
        if (payload.isEmpty) continue;
        batch.set(_collection.doc(docId), payload);
      }
      await batch.commit();
      _seedChecked = true;
    } catch (e) {
      // Leave `_seedChecked` false so a later authenticated call can retry.
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
