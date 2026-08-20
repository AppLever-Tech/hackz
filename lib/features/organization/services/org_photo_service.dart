import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../attachment/models/attachment_model.dart';
import '../../attachment/services/attachment_service.dart';

/// Uploads organisation icons to Firebase Storage.
abstract final class OrgPhotoService {
  static Future<({String photoUrl, String thumbnailUrl})> uploadLogo({
    required String orgId,
    required PlatformFile file,
  }) async {
    final String safeOrg = orgId.trim().isEmpty ? 'pending' : orgId.trim();
    final String ext = (file.extension ?? 'jpg').trim().toLowerCase();
    final String folder = AttachmentService.folderForEntity(
      entityType: AttachmentEntityType.organization,
      orgId: safeOrg,
      entityId: safeOrg,
    );
    final String storagePath = '$folder/logo_${DateTime.now().millisecondsSinceEpoch}.$ext';

    final Reference ref = FirebaseStorage.instance.ref(storagePath);
    await AttachmentService.createUploadTask(ref: ref, file: file);
    final String url = await ref.getDownloadURL();
    return (photoUrl: url, thumbnailUrl: url);
  }
}
