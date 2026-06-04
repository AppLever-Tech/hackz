import 'package:cloud_firestore/cloud_firestore.dart';

enum AttachmentEntityType {
  organization('organization'),
  problem('problem'),
  idea('idea'),
  payment('payment');

  const AttachmentEntityType(this.value);
  final String value;

  static AttachmentEntityType fromRaw(String raw) {
    final normalized = raw.trim().toLowerCase();
    switch (normalized) {
      case 'organization':
        return AttachmentEntityType.organization;
      case 'idea':
        return AttachmentEntityType.idea;
      case 'payment':
        return AttachmentEntityType.payment;
      case 'problem':
      default:
        return AttachmentEntityType.problem;
    }
  }
}

enum AttachmentType {
  image('image'),
  video('video'),
  pdf('pdf'),
  ppt('ppt'),
  document('document');

  const AttachmentType(this.value);
  final String value;
}

class AttachmentModel {
  const AttachmentModel({
    required this.attachmentId,
    required this.entityType,
    required this.entityId,
    required this.orgId,
    required this.departmentCode,
    required this.fileName,
    required this.storagePath,
    required this.downloadUrl,
    required this.fileType,
    required this.mimeType,
    required this.sizeInBytes,
    required this.thumbnailUrl,
    required this.uploadedBy,
    required this.createdAt,
    required this.isActive,
  });

  final String attachmentId;
  final AttachmentEntityType entityType;
  final String entityId;
  final String orgId;
  final String departmentCode;
  final String fileName;
  final String storagePath;
  final String downloadUrl;
  final String fileType;
  final String mimeType;
  final int sizeInBytes;
  final String? thumbnailUrl;
  final String uploadedBy;
  final DateTime createdAt;
  final bool isActive;

  AttachmentType get attachmentType {
    final normalizedMime = mimeType.trim().toLowerCase();
    final normalizedType = fileType.trim().toLowerCase();
    final normalizedName = fileName.trim().toLowerCase();
    if (normalizedMime.startsWith('image/') ||
        normalizedType == 'image' ||
        normalizedName.endsWith('.png') ||
        normalizedName.endsWith('.jpg') ||
        normalizedName.endsWith('.jpeg') ||
        normalizedName.endsWith('.gif') ||
        normalizedName.endsWith('.webp')) {
      return AttachmentType.image;
    }
    if (normalizedMime.startsWith('video/') ||
        normalizedType == 'video' ||
        normalizedName.endsWith('.mp4') ||
        normalizedName.endsWith('.mov') ||
        normalizedName.endsWith('.webm') ||
        normalizedName.endsWith('.mkv')) {
      return AttachmentType.video;
    }
    if (normalizedMime.contains('pdf') || normalizedType == 'pdf' || normalizedName.endsWith('.pdf')) {
      return AttachmentType.pdf;
    }
    if (normalizedMime.contains('presentation') ||
        normalizedType == 'ppt' ||
        normalizedName.endsWith('.ppt') ||
        normalizedName.endsWith('.pptx')) {
      return AttachmentType.ppt;
    }
    return AttachmentType.document;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'attachmentId': attachmentId,
      'entityType': entityType.value,
      'entityId': entityId,
      'orgId': orgId,
      'departmentCode': departmentCode,
      'fileName': fileName,
      'storagePath': storagePath,
      'downloadUrl': downloadUrl,
      'fileType': fileType,
      'mimeType': mimeType,
      'sizeInBytes': sizeInBytes,
      'thumbnailUrl': thumbnailUrl,
      'uploadedBy': uploadedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  factory AttachmentModel.fromMap(String id, Map<String, dynamic> map) {
    return AttachmentModel(
      attachmentId: ((map['attachmentId'] as String?) ?? '').trim().isEmpty
          ? id
          : ((map['attachmentId'] as String?) ?? '').trim(),
      entityType: AttachmentEntityType.fromRaw((map['entityType'] as String?) ?? ''),
      entityId: ((map['entityId'] as String?) ?? '').trim(),
      orgId: ((map['orgId'] as String?) ?? '').trim(),
      departmentCode: ((map['departmentCode'] as String?) ?? '').trim().toUpperCase(),
      fileName: ((map['fileName'] as String?) ?? '').trim(),
      storagePath: ((map['storagePath'] as String?) ?? '').trim(),
      downloadUrl: ((map['downloadUrl'] as String?) ?? '').trim(),
      fileType: ((map['fileType'] as String?) ?? '').trim(),
      mimeType: ((map['mimeType'] as String?) ?? '').trim(),
      sizeInBytes: (map['sizeInBytes'] as num?)?.toInt() ?? 0,
      thumbnailUrl: (map['thumbnailUrl'] as String?)?.trim().isEmpty == true
          ? null
          : (map['thumbnailUrl'] as String?)?.trim(),
      uploadedBy: ((map['uploadedBy'] as String?) ?? '').trim(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: (map['isActive'] as bool?) ?? true,
    );
  }
}
