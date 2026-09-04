import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:hackz/features/attachment/services/attachment_service.dart';
import 'package:hackz/core/firebase/hackz_firebase.dart';

/// Uploads hkzUsers profile photos to Firebase Storage.
abstract final class UserPhotoService {
  static Future<({String photoUrl, String thumbnailUrl})> uploadProfilePhoto({
    required String orgId,
    required String userId,
    required PlatformFile file,
  }) async {
    final String safeOrg = orgId.trim().isEmpty ? 'unknown' : orgId.trim();
    final String safeUser = userId.trim().isEmpty ? 'pending' : userId.trim();
    final String ext = (file.extension ?? 'jpg').trim().toLowerCase();
    final String storagePath = 'users/$safeOrg/$safeUser/profile_${DateTime.now().millisecondsSinceEpoch}.$ext';

    final Reference ref = HackzFirebase.current.storage.ref(storagePath);
    await AttachmentService.createUploadTask(ref: ref, file: file);
    final String url = await ref.getDownloadURL();
    return (photoUrl: url, thumbnailUrl: url);
  }
}
