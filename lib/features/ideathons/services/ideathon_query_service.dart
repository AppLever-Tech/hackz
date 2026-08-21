import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/firestore_utils.dart';
import '../../user/models/user_model.dart';
import '../models/ideathon_model.dart';
import '../models/ideathon_status.dart';

class IdeathonListRow {
  const IdeathonListRow({required this.ideathon});

  final IdeathonModel ideathon;
}

class IdeathonQueryParams {
  const IdeathonQueryParams({
    required this.viewer,
    this.search = '',
    this.statusFilters = const <IdeathonStatus>{},
    this.departmentFilters = const <String>{},
  });

  final UserModel viewer;
  final String search;
  final Set<IdeathonStatus> statusFilters;
  final Set<String> departmentFilters;
}

abstract final class IdeathonQueryService {
  IdeathonQueryService._();

  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<List<IdeathonListRow>> fetch(IdeathonQueryParams params) async {
    final String orgId = params.viewer.orgId.trim();
    if (orgId.isEmpty) return const <IdeathonListRow>[];

    final QuerySnapshot<Map<String, dynamic>> snap = await _db
        .collection(FirestoreUtils.hkzIdeathons)
        .where('orgId', isEqualTo: orgId)
        .get();

    final String search = params.search.trim().toLowerCase();
    final String viewerDept = params.viewer.departmentCode.trim().toUpperCase();

    final List<IdeathonListRow> rows = <IdeathonListRow>[];
    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snap.docs) {
      final IdeathonModel ideathon = IdeathonModel.fromMap(doc.id, doc.data());
      if (viewerDept.isNotEmpty && ideathon.departmentId.trim().toUpperCase() != viewerDept) continue;
      if (params.statusFilters.isNotEmpty && !params.statusFilters.contains(ideathon.status)) continue;
      if (params.departmentFilters.isNotEmpty &&
          !params.departmentFilters.contains(ideathon.departmentId.trim().toUpperCase())) {
        continue;
      }
      if (search.isNotEmpty) {
        final String haystack =
            '${ideathon.name} ${ideathon.description} ${ideathon.ideathonType.label}'.toLowerCase();
        if (!haystack.contains(search)) continue;
      }
      rows.add(IdeathonListRow(ideathon: ideathon));
    }

    rows.sort((IdeathonListRow a, IdeathonListRow b) =>
        b.ideathon.startDateTime.compareTo(a.ideathon.startDateTime));
    return rows;
  }
}
