import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;

import '../../../core/branding/hackz_brand_image_key.dart';
import '../../../utils/firestore_utils.dart';
import 'certificate_pdf_assets.dart';

/// Resolves the college logo saved on the tenant organisation record for PDF certificates.
abstract final class CertificateOrganisationLogoLoader {
  CertificateOrganisationLogoLoader._();

  static final Map<String, pw.MemoryImage?> _cache = <String, pw.MemoryImage?>{};

  static Future<pw.ImageProvider?> loadForOrg(String orgId, {bool preferServer = true}) async {
    final String id = orgId.trim();
    if (id.isEmpty) return null;
    if (_cache.containsKey(id)) return _cache[id];

    pw.MemoryImage? resolved;
    try {
      final org = await FirestoreUtils.fetchOrganization(id, preferServer: preferServer);
      final String url = org?.avatarUrl.trim() ?? '';
      if (url.isNotEmpty) {
        resolved = await _downloadPdfImage(url);
      }
    } catch (_) {
      resolved = null;
    }
    _cache[id] = resolved;
    return resolved;
  }

  static Future<pw.MemoryImage?> _downloadPdfImage(String url) async {
    try {
      final http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) return null;
      final Uint8List keyed = HackzBrandImageKey.pngWithTransparentBackground(response.bodyBytes);
      return CertificatePdfAssets.memoryImage(keyed);
    } catch (_) {
      return null;
    }
  }
}
