import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../utils/firestore_utils.dart';
import '../constants/app_metadata_keys.dart';
import '../models/app_metadata_document.dart';
import '../seed/default_metadata_seed.dart';

/// Reads and writes global app metadata in `hkzAppMetadata`.
abstract final class AppMetadataService {
  AppMetadataService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static bool _seedChecked = false;

  static CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(FirestoreUtils.hkzAppMetadata);

  /// Seeds bundled defaults when the collection is empty. Safe to call repeatedly.
  static Future<void> ensureSeeded() async {
    if (_seedChecked) return;
    _seedChecked = true;
    try {
      final QuerySnapshot<Map<String, dynamic>> snap = await _collection.limit(1).get();
      if (snap.docs.isNotEmpty) return;

      final WriteBatch batch = _db.batch();
      for (final String docId in AppMetadataKeys.all) {
        final Map<String, dynamic> payload = await DefaultMetadataSeed.firestorePayloadFor(docId);
        if (payload.isEmpty) continue;
        batch.set(_collection.doc(docId), payload);
      }
      await batch.commit();
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
