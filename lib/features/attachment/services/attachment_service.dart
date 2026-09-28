import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'package:hackz/features/attachment/models/attachment_model.dart';
import 'package:hackz/utils/firestore_utils.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';

class AttachmentService {
  AttachmentService._();

  static FirebaseFirestore get _db => HackzFirebase.current.firestore;
  static FirebaseStorage get _storage => HackzFirebase.current.storage;

  /// Cross-platform upload helper:
  /// - Web: putData(file.bytes)
  /// - Mobile/Desktop: putFile(File(path)) when path exists, else putData(bytes)
  static UploadTask createUploadTask({
    required Reference ref,
    required PlatformFile file,
  }) {
    final SettableMetadata metadata = metadataFor(file);
    if (kIsWeb) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw StateError('Missing bytes for web upload: ${file.name}');
      }
      return ref.putData(bytes, metadata);
    }

    final path = file.path;
    if (path != null && path.trim().isNotEmpty) {
      return ref.putFile(File(path), metadata);
    }
    final bytes = file.bytes;
    if (bytes != null && bytes.isNotEmpty) {
      return ref.putData(bytes, metadata);
    }
    throw StateError('Missing file path/bytes: ${file.name}');
  }

  /// Object name for Storage. Keeps the original display name in Firestore.
  static String storageObjectName(String originalName) {
    final String trimmed = originalName.trim();
    final int dot = trimmed.lastIndexOf('.');
    String stem = trimmed;
    String ext = '';
    if (dot > 0 && dot < trimmed.length - 1) {
      stem = trimmed.substring(0, dot);
      ext = trimmed.substring(dot + 1).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    }
    String safe = stem.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    safe = safe.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
    if (safe.isEmpty) safe = 'file';
    if (safe.length > 80) safe = safe.substring(0, 80);
    return ext.isEmpty ? safe : '$safe.$ext';
  }

  static SettableMetadata metadataFor(PlatformFile file) {
    final String ext = (file.extension ?? '').trim().toLowerCase();
    return SettableMetadata(contentType: _mimeForExt(ext));
  }

  static String folderForEntity({
    required AttachmentEntityType entityType,
    required String orgId,
    required String entityId,
  }) {
    switch (entityType) {
      case AttachmentEntityType.organization:
        return 'orgs/$orgId/logos';
      case AttachmentEntityType.problem:
        return 'problems/$entityId';
      case AttachmentEntityType.idea:
        return 'ideas/$entityId';
      case AttachmentEntityType.payment:
        return 'payments/$entityId';
      case AttachmentEntityType.feedback:
        return 'feedback/$entityId';
    }
  }

  static Future<List<AttachmentModel>> uploadAttachments({
    required AttachmentEntityType entityType,
    required String entityId,
    required String orgId,
    required String departmentCode,
    required String uploadedBy,
    required List<PlatformFile> files,
    String? fileType,
  }) async {
    if (files.isEmpty) return const <AttachmentModel>[];
    if (entityType != AttachmentEntityType.feedback) {
      HackzFirebase.assertOrganisationStorage();
    }
    final folder = folderForEntity(entityType: entityType, orgId: orgId, entityId: entityId);
    final created = <AttachmentModel>[];
    final failedDetails = <String>[];

    for (final file in files) {
      final name = file.name.trim().isEmpty ? 'file_${DateTime.now().millisecondsSinceEpoch}' : file.name.trim();
      final ext = (file.extension ?? '').trim().toLowerCase();
      final String objectName = storageObjectName(name);
      final storagePath = '$folder/$objectName';
      try {
        final ref = _storage.ref(storagePath);
        final task = createUploadTask(ref: ref, file: file);
        await task;
        final url = await ref.getDownloadURL();
        final doc = _db.collection(FirestoreUtils.hkzAttachments).doc();
        final model = AttachmentModel(
          attachmentId: doc.id,
          entityType: entityType,
          entityId: entityId,
          orgId: orgId,
          departmentCode: departmentCode.trim().toUpperCase(),
          fileName: name,
          storagePath: storagePath,
          downloadUrl: url,
          fileType: (fileType ?? ext).trim().isEmpty ? 'file' : (fileType ?? ext).trim().toLowerCase(),
          mimeType: _mimeForExt(ext),
          sizeInBytes: file.size,
          thumbnailUrl: null,
          uploadedBy: uploadedBy,
          createdAt: DateTime.now(),
          isActive: true,
        );
        await doc.set(model.toMap(), SetOptions(merge: true));
        created.add(model);
      } on FirebaseException catch (e) {
        final msg = (e.message ?? '').trim();
        final details = msg.isEmpty ? e.code : '${e.code}: $msg';
        failedDetails.add('$name ($details)');
      } catch (e) {
        failedDetails.add('$name ($e)');
      }
    }

    if (failedDetails.isNotEmpty) {
      throw StateError('Failed to upload attachment(s): ${failedDetails.join(', ')}');
    }
    return created;
  }

  static Future<AttachmentModel?> fetchById(String attachmentId) async {
    final String id = attachmentId.trim();
    if (id.isEmpty) return null;
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _db.collection(FirestoreUtils.hkzAttachments).doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    final AttachmentModel model = AttachmentModel.fromMap(doc.id, doc.data()!);
    if (!model.isActive) return null;
    return model;
  }

  static Future<List<AttachmentModel>> fetchActiveAttachments({
    required AttachmentEntityType entityType,
    required String entityId,
  }) async {
    final snap = await _db
        .collection(FirestoreUtils.hkzAttachments)
        .where('entityType', isEqualTo: entityType.value)
        .where('entityId', isEqualTo: entityId.trim())
        .where('isActive', isEqualTo: true)
        .get();
    final items = snap.docs.map((d) => AttachmentModel.fromMap(d.id, d.data())).toList(growable: false);
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  static Future<void> deactivateEntityAttachments({
    required AttachmentEntityType entityType,
    required String entityId,
  }) async {
    final snap = await _db
        .collection(FirestoreUtils.hkzAttachments)
        .where('entityType', isEqualTo: entityType.value)
        .where('entityId', isEqualTo: entityId.trim())
        .where('isActive', isEqualTo: true)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.set(doc.reference, <String, dynamic>{'isActive': false}, SetOptions(merge: true));
    }
    await batch.commit();
  }

  static String _mimeForExt(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
