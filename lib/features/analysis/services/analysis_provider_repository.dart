import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/hackz_firebase.dart';
import '../models/analysis_provider_models.dart';

abstract final class AnalysisProviderRepository {
  AnalysisProviderRepository._();

  static const String collection = 'hkzAnalysisProviderConfig';

  static CollectionReference<Map<String, dynamic>> get _col =>
      HackzFirebase.current.firestore.collection(collection);

  static Stream<AnalysisProviderPublicConfig> watchOrganisation(String organisationId) {
    final String id = organisationId.trim();
    return _col.doc(id).snapshots().map((DocumentSnapshot<Map<String, dynamic>> snap) {
      if (!snap.exists || snap.data() == null) {
        return AnalysisProviderPublicConfig.empty(id);
      }
      return AnalysisProviderPublicConfig.fromMap(id, snap.data()!);
    });
  }
}
