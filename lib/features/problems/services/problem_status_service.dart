import '../../../utils/firestore_utils.dart';
import '../models/problem_status.dart';

class ProblemStatusService {
  ProblemStatusService._();

  static Future<void> setStatus({
    required String problemId,
    required ProblemStatus status,
  }) async {
    await FirestoreUtils.updateProblem(problemId, <String, dynamic>{
      'status': status.value,
    });
  }

  static Future<void> activate(String problemId) async {
    await setStatus(problemId: problemId, status: ProblemStatus.active);
  }

  static Future<void> deactivate(String problemId) async {
    await setStatus(problemId: problemId, status: ProblemStatus.inactive);
  }

  static Future<int> activateMany(Iterable<String> problemIds) async {
    var count = 0;
    for (final String id in problemIds) {
      final String trimmed = id.trim();
      if (trimmed.isEmpty) continue;
      await activate(trimmed);
      count++;
    }
    return count;
  }
}
