import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../utils/firestore_utils.dart';

class ProblemUtils {
  ProblemUtils._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<String> generateProblemNumber() async {
    final counterRef = _db
        .collection(FirestoreUtils.hkzCounters)
        .doc('problemCounter');

    final nextNumber = await _db.runTransaction<int>((transaction) async {
      final snap = await transaction.get(counterRef);
      final last = (snap.data()?['lastNumber'] as num?)?.toInt() ?? 0;
      final next = last + 1;
      transaction.set(counterRef, <String, dynamic>{'lastNumber': next}, SetOptions(merge: true));
      return next;
    });

    final padded = nextNumber.toString().padLeft(6, '0');
    return 'HZP$padded';
  }

  static Future<List<String>> uploadAttachments({
    required List<PlatformFile> files,
    required String problemNumber,
  }) async {
    if (files.isEmpty) return const <String>[];
    final urls = <String>[];
    final failedFiles = <String>[];
    for (final file in files) {
      final filename = file.name.trim().isEmpty
          ? 'attachment_${DateTime.now().millisecondsSinceEpoch}'
          : file.name;
      final ref = _storage.ref('problems/$problemNumber/$filename');

      try {
        UploadTask task;
        if (kIsWeb) {
          final bytes = file.bytes;
          if (bytes == null || bytes.isEmpty) {
            failedFiles.add(filename);
            continue;
          }
          task = ref.putData(bytes);
        } else {
          final path = file.path;
          if (path == null || path.trim().isEmpty) {
            failedFiles.add(filename);
            continue;
          }
          task = ref.putFile(File(path));
        }

        await task;
        final url = await ref.getDownloadURL();
        urls.add(url);
      } catch (_) {
        failedFiles.add(filename);
      }
    }

    if (failedFiles.isNotEmpty) {
      throw StateError('Failed to upload attachment(s): ${failedFiles.join(', ')}');
    }
    return urls;
  }
}
