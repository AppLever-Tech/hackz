import '../../models/attachment_model.dart';

/// Read-only attachment totals for workspace UIs (no file names or URLs).
class WorkspaceAttachmentCounts {
  const WorkspaceAttachmentCounts({
    required this.totalCount,
    required this.countByType,
  });

  static const WorkspaceAttachmentCounts empty = WorkspaceAttachmentCounts(
    totalCount: 0,
    countByType: <AttachmentType, int>{},
  );

  final int totalCount;
  final Map<AttachmentType, int> countByType;

  bool get isEmpty => totalCount == 0;

  static WorkspaceAttachmentCounts fromModels(Iterable<AttachmentModel> items) {
    final Map<AttachmentType, int> byType = <AttachmentType, int>{};
    var total = 0;
    for (final AttachmentModel a in items) {
      total++;
      byType[a.attachmentType] = (byType[a.attachmentType] ?? 0) + 1;
    }
    return WorkspaceAttachmentCounts(totalCount: total, countByType: byType);
  }
}
