import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:hackz/core/firebase/hackz_firebase.dart';

/// One Firestore set used by CSV import. Rollback deletes only [deleteOnRollback] docs.
class ImportAtomicWrite {
  const ImportAtomicWrite({
    required this.ref,
    required this.data,
    this.merge = false,
    this.deleteOnRollback = true,
  });

  final DocumentReference<Map<String, dynamic>> ref;
  final Map<String, dynamic> data;
  final bool merge;
  final bool deleteOnRollback;
}

/// Commits import writes with existing Firestore batches. If a later batch fails,
/// newly created documents are deleted so the import leaves zero records.
abstract final class ImportAtomicWriter {
  ImportAtomicWriter._();

  static const int maxOpsPerBatch = 500;

  static FirebaseFirestore get _db => HackzFirebase.current.firestore;

  static Future<void> commit(List<ImportAtomicWrite> writes) async {
    if (writes.isEmpty) return;
    final List<DocumentReference<Map<String, dynamic>>> created = <DocumentReference<Map<String, dynamic>>>[];
    try {
      for (var offset = 0; offset < writes.length; offset += maxOpsPerBatch) {
        final int end = offset + maxOpsPerBatch > writes.length ? writes.length : offset + maxOpsPerBatch;
        final List<ImportAtomicWrite> chunk = writes.sublist(offset, end);
        final WriteBatch batch = _db.batch();
        for (final ImportAtomicWrite write in chunk) {
          if (write.merge) {
            batch.set(write.ref, write.data, SetOptions(merge: true));
          } else {
            batch.set(write.ref, write.data);
          }
        }
        await batch.commit();
        created.addAll(
          chunk.where((ImportAtomicWrite w) => w.deleteOnRollback).map((ImportAtomicWrite w) => w.ref),
        );
      }
    } catch (e) {
      await _deleteCreated(created);
      throw StateError('Import failed and no records were saved. $e');
    }
  }

  static Future<void> _deleteCreated(List<DocumentReference<Map<String, dynamic>>> refs) async {
    for (var offset = 0; offset < refs.length; offset += maxOpsPerBatch) {
      final int end = offset + maxOpsPerBatch > refs.length ? refs.length : offset + maxOpsPerBatch;
      final WriteBatch batch = _db.batch();
      for (final DocumentReference<Map<String, dynamic>> ref in refs.sublist(offset, end)) {
        batch.delete(ref);
      }
      try {
        await batch.commit();
      } catch (_) {
        // Best-effort compensation; original failure is rethrown by [commit].
      }
    }
  }
}
