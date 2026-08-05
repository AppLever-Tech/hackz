import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../../utils/firestore_utils.dart';
import '../../app_metadata/constants/app_metadata_keys.dart';
import '../../app_metadata/models/app_metadata_document.dart';
import '../../app_metadata/services/app_metadata_service.dart';
import '../../attachment/models/attachment_model.dart';
import '../../attachment/services/attachment_service.dart';
import '../../org_settings/constants/org_setting_keys.dart';
import '../../org_settings/services/org_settings_service.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../../user/services/user_role_labels.dart';
import '../models/feedback_model.dart';
import '../models/feedback_status.dart';
import '../models/feedback_type.dart';

/// Firestore + validation for the Feedback feature.
///
/// Named [HackzFeedbackService] to avoid clashing with toast [FeedbackService].
abstract final class HackzFeedbackService {
  HackzFeedbackService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(FirestoreUtils.hkzFeedback);

  static const int maxDescriptionWords = 300;

  static int wordCount(String text) {
    final String t = text.trim();
    if (t.isEmpty) return 0;
    return t.split(RegExp(r'\s+')).where((String w) => w.isNotEmpty).length;
  }

  static String detectPlatform() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  static Future<String> resolveAppVersion() async {
    try {
      final AppMetadataDocument? doc =
          await AppMetadataService.fetch(AppMetadataKeys.appInfo);
      if (doc != null) {
        final String v = doc.appInfo.version.trim();
        final String b = doc.appInfo.buildNumber.trim();
        if (v.isNotEmpty && b.isNotEmpty) return '$v+$b';
        if (v.isNotEmpty) return v;
      }
    } catch (_) {}
    return '1.0.2';
  }

  static Future<bool> isFeedbackEnabledFor(UserModel user) async {
    if (UserRole.fromCode(user.role) == UserRole.sysAdmin) return true;
    final String orgId = user.orgId.trim();
    if (orgId.isEmpty) return false;
    await OrgSettingsService.instance.ensureLoaded(orgId: orgId);
    final Object? raw =
        OrgSettingsService.instance.valuesSnapshot[OrgSettingKeys.enableFeedback];
    if (raw is bool) return raw;
    return true;
  }

  static Future<int> maxScreenshotSizeMb(UserModel user) async {
    final String orgId = user.orgId.trim();
    if (orgId.isNotEmpty) {
      await OrgSettingsService.instance.ensureLoaded(orgId: orgId);
      final Object? raw = OrgSettingsService.instance
          .valuesSnapshot[OrgSettingKeys.maxFeedbackScreenshotSizeMB];
      if (raw is num) return raw.toInt().clamp(1, 25);
    }
    return 5;
  }

  static Future<int> maxPerUserPerDay(UserModel user) async {
    final String orgId = user.orgId.trim();
    if (orgId.isNotEmpty) {
      await OrgSettingsService.instance.ensureLoaded(orgId: orgId);
      final Object? raw = OrgSettingsService.instance
          .valuesSnapshot[OrgSettingKeys.maxFeedbackPerUserPerDay];
      if (raw is num) return raw.toInt().clamp(1, 50);
    }
    return 5;
  }

  static Future<int> countTodayForUser(String userId) async {
    final DateTime now = DateTime.now();
    final DateTime start = DateTime(now.year, now.month, now.day);
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _col.where('submittedBy', isEqualTo: userId).get();
    int count = 0;
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final Object? raw = doc.data()['createdAt'];
      final DateTime? created = raw is Timestamp ? raw.toDate() : null;
      if (created != null && !created.isBefore(start)) count++;
    }
    return count;
  }

  static Future<int> countOpenAll() async {
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _col.where('status', isEqualTo: FeedbackStatus.open.value).get();
    return snap.size;
  }

  static String? validateScreenshot({
    required PlatformFile? file,
    required int maxMb,
  }) {
    if (file == null) return null;
    final String ext = (file.extension ?? '').trim().toLowerCase();
    if (ext != 'png' && ext != 'jpg' && ext != 'jpeg') {
      return 'Screenshot must be a PNG or JPEG image.';
    }
    final int bytes = file.size;
    final int maxBytes = maxMb * 1024 * 1024;
    if (bytes > maxBytes) {
      return 'Screenshot exceeds the maximum size of $maxMb MB.';
    }
    return null;
  }

  static Future<FeedbackModel> submit({
    required UserModel user,
    required FeedbackType type,
    required String title,
    required String description,
    required String screenName,
    PlatformFile? screenshot,
  }) async {
    final bool enabled = await isFeedbackEnabledFor(user);
    if (!enabled) {
      throw StateError('Feedback is currently disabled for your organization.');
    }

    final String cleanTitle = title.trim();
    final String cleanDescription = description.trim();
    if (cleanTitle.isEmpty) throw StateError('Title is required.');
    if (cleanDescription.isEmpty) throw StateError('Description is required.');
    if (wordCount(cleanDescription) > maxDescriptionWords) {
      throw StateError('Description must be $maxDescriptionWords words or fewer.');
    }

    final int dailyMax = await maxPerUserPerDay(user);
    final int todayCount = await countTodayForUser(user.userId);
    if (todayCount >= dailyMax) {
      throw StateError(
        'You have reached the daily limit of $dailyMax feedback submissions.',
      );
    }

    final int maxMb = await maxScreenshotSizeMb(user);
    final String? shotError = validateScreenshot(file: screenshot, maxMb: maxMb);
    if (shotError != null) throw StateError(shotError);

    final DocumentReference<Map<String, dynamic>> doc = _col.doc();
    final String feedbackId = doc.id;
    String? screenshotUrl;

    if (screenshot != null) {
      final List<AttachmentModel> uploaded = await AttachmentService.uploadAttachments(
        entityType: AttachmentEntityType.feedback,
        entityId: feedbackId,
        orgId: user.orgId.trim().isEmpty ? 'platform' : user.orgId.trim(),
        departmentCode: user.departmentCode,
        uploadedBy: user.userId,
        files: <PlatformFile>[screenshot],
        fileType: 'image',
      );
      if (uploaded.isNotEmpty) {
        screenshotUrl = uploaded.first.downloadUrl;
      }
    }

    final DateTime now = DateTime.now();
    final String appVersion = await resolveAppVersion();
    final String orgId = user.orgId.trim();
    final String organizationName = await resolveOrganizationName(orgId);
    final FeedbackModel model = FeedbackModel(
      feedbackId: feedbackId,
      organizationId: orgId,
      organizationName: organizationName,
      departmentId: user.departmentCode.trim(),
      submittedBy: user.userId,
      submittedByName: user.displayName.trim().isEmpty ? user.userId : user.displayName.trim(),
      role: UserRoleLabels.labelForCode(user.role),
      type: type,
      title: cleanTitle,
      description: cleanDescription,
      screenshotUrl: screenshotUrl,
      status: FeedbackStatus.open,
      internalNotes: '',
      platform: detectPlatform(),
      appVersion: appVersion,
      screenName: screenName.trim().isEmpty ? 'App' : screenName.trim(),
      createdAt: now,
      updatedAt: now,
    );

    await doc.set(model.toMap());
    return model;
  }

  static Future<String> resolveOrganizationName(String orgId) async {
    final String id = orgId.trim();
    if (id.isEmpty) return '';
    try {
      final org = await FirestoreUtils.fetchOrganization(id);
      final String name = org?.name.trim() ?? '';
      return name;
    } catch (_) {
      return '';
    }
  }

  /// Fills [FeedbackModel.organizationName] for rows that only have an org id.
  static Future<List<FeedbackModel>> hydrateOrganizationNames(
    List<FeedbackModel> rows,
  ) async {
    final Set<String> missing = rows
        .where((FeedbackModel f) =>
            f.organizationName.trim().isEmpty && f.organizationId.trim().isNotEmpty)
        .map((FeedbackModel f) => f.organizationId.trim())
        .toSet();
    if (missing.isEmpty) return rows;

    final Map<String, String> names = <String, String>{};
    await Future.wait(
      missing.map((String id) async {
        names[id] = await resolveOrganizationName(id);
      }),
    );

    return rows
        .map((FeedbackModel f) {
          if (f.organizationName.trim().isNotEmpty) return f;
          final String n = names[f.organizationId.trim()] ?? '';
          if (n.isEmpty) return f;
          return FeedbackModel(
            feedbackId: f.feedbackId,
            organizationId: f.organizationId,
            organizationName: n,
            departmentId: f.departmentId,
            submittedBy: f.submittedBy,
            submittedByName: f.submittedByName,
            role: f.role,
            type: f.type,
            title: f.title,
            description: f.description,
            screenshotUrl: f.screenshotUrl,
            status: f.status,
            internalNotes: f.internalNotes,
            platform: f.platform,
            appVersion: f.appVersion,
            screenName: f.screenName,
            createdAt: f.createdAt,
            updatedAt: f.updatedAt,
          );
        })
        .toList(growable: false);
  }

  static Future<List<FeedbackModel>> fetchMine(String userId) async {
    final QuerySnapshot<Map<String, dynamic>> snap =
        await _col.where('submittedBy', isEqualTo: userId).get();
    final List<FeedbackModel> rows = snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> d) =>
            FeedbackModel.fromMap(d.data(), id: d.id))
        .toList(growable: true);
    rows.sort((FeedbackModel a, FeedbackModel b) => b.createdAt.compareTo(a.createdAt));
    return hydrateOrganizationNames(rows);
  }

  static Future<List<FeedbackModel>> fetchAll() async {
    final QuerySnapshot<Map<String, dynamic>> snap = await _col.limit(500).get();
    final List<FeedbackModel> rows = snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> d) =>
            FeedbackModel.fromMap(d.data(), id: d.id))
        .toList(growable: true);
    rows.sort((FeedbackModel a, FeedbackModel b) => b.createdAt.compareTo(a.createdAt));
    return hydrateOrganizationNames(rows);
  }

  static Future<FeedbackModel?> fetchById(String feedbackId) async {
    final DocumentSnapshot<Map<String, dynamic>> snap =
        await _col.doc(feedbackId.trim()).get();
    if (!snap.exists || snap.data() == null) return null;
    return FeedbackModel.fromMap(snap.data()!, id: snap.id);
  }

  static Future<void> updateAdminFields({
    required String feedbackId,
    required FeedbackStatus status,
    required String internalNotes,
  }) async {
    await _col.doc(feedbackId.trim()).update(<String, dynamic>{
      'status': status.value,
      'internalNotes': internalNotes.trim(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
