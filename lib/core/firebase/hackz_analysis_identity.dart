import 'hackz_firebase.dart';

/// Control Plane configuration for the Hackz Analysis Service invoke URL.
class HackzAnalysisIdentity {
  const HackzAnalysisIdentity({required this.invokeUrl});

  final String invokeUrl;

  static const String collectionName = 'hkzAnalysisConfig';
  static const String documentId = 'hackz';

  static HackzAnalysisIdentity? _cached;

  static Future<HackzAnalysisIdentity> load() async {
    final HackzAnalysisIdentity? cached = _cached;
    if (cached != null && cached.invokeUrl.isNotEmpty) return cached;

    String invokeUrl = '';
    try {
      final doc = await HackzFirebase.controlPlane.firestore
          .collection(collectionName)
          .doc(documentId)
          .get();
      invokeUrl = ((doc.data()?['invokeUrl'] as String?) ?? '').trim();
    } catch (_) {
      invokeUrl = '';
    }
    final HackzAnalysisIdentity identity = HackzAnalysisIdentity(invokeUrl: invokeUrl);
    if (invokeUrl.isNotEmpty) _cached = identity;
    return identity;
  }

  static void clearCache() {
    _cached = null;
  }
}
