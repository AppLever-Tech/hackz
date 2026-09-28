import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;

import '../../../core/firebase/hackz_firebase.dart';
import '../../../utils/firestore_utils.dart';
import '../../organization/models/organization_model.dart';
import '../../organization/services/organisation_access.dart';
import 'certificate_pdf_assets.dart';

/// Resolves the college logo saved on the tenant organisation record for PDF certificates.
abstract final class CertificateOrganisationLogoLoader {
  CertificateOrganisationLogoLoader._();

  static final Map<String, pw.MemoryImage> _cache = <String, pw.MemoryImage>{};

  /// Call after organisation logo upload so the next PDF uses fresh Storage bytes.
  static void evictCacheForOrg(String orgId) {
    _cache.remove(orgId.trim());
  }

  /// [primaryOrgId] is usually the event's org id; [fallbackOrgId] is the signed-in user org.
  static Future<pw.ImageProvider?> loadForOrg(
    String primaryOrgId, {
    String fallbackOrgId = '',
    bool preferServer = true,
  }) async {
    final String id = _resolveOrgId(primaryOrgId, fallbackOrgId);
    if (id.isEmpty) return null;

    final pw.MemoryImage? cached = _cache[id];
    if (cached != null) return cached;

    try {
      final OrganizationModel? org = await FirestoreUtils.fetchOrganization(id, preferServer: preferServer);

      String? url = (org?.photoUrl ?? '').trim();
      if (url.isEmpty) {
        url = org?.avatarUrl.trim();
      }
      if (url != null && url.isNotEmpty) {
        final pw.ImageProvider? fromStorage = await loadFromAvatarUrl(url, cacheKey: id);
        if (fromStorage != null) return fromStorage;
      }

      final OrganizationModel? cp = await OrganisationAccess.fetch(id);
      final String cpPhoto = (cp?.photoUrl ?? '').trim();
      final String? cpUrl = cpPhoto.isNotEmpty ? cpPhoto : cp?.avatarUrl.trim();
      if (cpUrl != null && cpUrl.isNotEmpty) {
        return loadFromAvatarUrl(cpUrl, cacheKey: id);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<pw.ImageProvider?> loadFromAvatarUrl(
    String avatarUrl, {
    required String cacheKey,
  }) async {
    final String url = avatarUrl.trim();
    if (url.isEmpty) return null;

    final String key = cacheKey.trim();
    if (key.isNotEmpty) {
      final pw.MemoryImage? cached = _cache[key];
      if (cached != null) return cached;
    }

    final Uint8List? raw = await _downloadBytes(url);
    if (raw == null || raw.isEmpty) return null;

    final pw.MemoryImage? resolved = CertificatePdfAssets.memoryImageForCertificateEmbed(raw);
    if (resolved == null) return null;

    if (key.isNotEmpty) {
      _cache[key] = resolved;
    }
    return resolved;
  }

  static String _resolveOrgId(String primary, String fallback) {
    for (final String candidate in <String>[primary, fallback, _contextOrgId()]) {
      final String id = candidate.trim();
      if (id.isNotEmpty) return id;
    }
    return '';
  }

  static String _contextOrgId() {
    try {
      return HackzFirebase.current.context.organisationId.trim();
    } catch (_) {
      return '';
    }
  }

  static Future<Uint8List?> _downloadBytes(String url) async {
    final String trimmed = url.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.contains('firebasestorage.googleapis.com') ||
        trimmed.contains('storage.googleapis.com')) {
      try {
        HackzFirebase.assertOrganisationStorage();
        final Reference ref = HackzFirebase.current.storage.refFromURL(trimmed);
        final Uint8List? data = await ref.getData(8 * 1024 * 1024);
        if (data != null && data.isNotEmpty) return data;
      } catch (_) {}
    }

    try {
      final http.Response response = await http.get(Uri.parse(trimmed));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
    } catch (_) {}
    return null;
  }
}
