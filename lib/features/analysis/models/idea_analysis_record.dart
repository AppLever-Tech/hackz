import 'package:cloud_firestore/cloud_firestore.dart';

import 'analysis_provider_models.dart';

enum IdeaAnalysisStatus {
  pending,
  processing,
  completed,
  failed;

  static IdeaAnalysisStatus parse(String raw) {
    return switch (raw.trim().toUpperCase()) {
      'PROCESSING' => IdeaAnalysisStatus.processing,
      'COMPLETED' => IdeaAnalysisStatus.completed,
      'FAILED' => IdeaAnalysisStatus.failed,
      _ => IdeaAnalysisStatus.pending,
    };
  }

  String get label => switch (this) {
        IdeaAnalysisStatus.pending => 'Pending',
        IdeaAnalysisStatus.processing => 'Processing',
        IdeaAnalysisStatus.completed => 'Completed',
        IdeaAnalysisStatus.failed => 'Failed',
      };
}

class IdeaAnalysisRecord {
  const IdeaAnalysisRecord({
    required this.analysisId,
    required this.ideaId,
    required this.organisationId,
    required this.provider,
    required this.status,
    required this.capabilities,
    this.similarityPercent,
    this.aiWritingPercent,
    this.matchingSourceCount,
    required this.fullReportAvailable,
    this.failureMessage,
    required this.createdAt,
    this.completedAt,
  });

  final String analysisId;
  final String ideaId;
  final String organisationId;
  final AnalysisProviderType provider;
  final IdeaAnalysisStatus status;
  final List<AnalysisCapability> capabilities;
  final double? similarityPercent;
  final double? aiWritingPercent;
  final int? matchingSourceCount;
  final bool fullReportAvailable;
  final String? failureMessage;
  final DateTime createdAt;
  final DateTime? completedAt;

  bool get isInProgress =>
      status == IdeaAnalysisStatus.pending || status == IdeaAnalysisStatus.processing;

  factory IdeaAnalysisRecord.fromMap(String id, Map<String, dynamic> map) {
    final List<AnalysisCapability> caps = <AnalysisCapability>[];
    final Object? rawCaps = map['capabilities'];
    if (rawCaps is List<dynamic>) {
      for (final Object? item in rawCaps) {
        final AnalysisCapability? cap = AnalysisCapability.parse('${item ?? ''}');
        if (cap != null) caps.add(cap);
      }
    }
    DateTime? completed;
    final Object? completedRaw = map['completedAt'];
    if (completedRaw is Timestamp) {
      completed = completedRaw.toDate();
    } else if (completedRaw is String && completedRaw.isNotEmpty) {
      completed = DateTime.tryParse(completedRaw);
    }
    DateTime created = DateTime.now().toUtc();
    final Object? createdRaw = map['createdAt'];
    if (createdRaw is Timestamp) {
      created = createdRaw.toDate();
    } else if (createdRaw is String && createdRaw.isNotEmpty) {
      created = DateTime.tryParse(createdRaw) ?? created;
    }

    double? readDouble(Object? raw) {
      if (raw == null) return null;
      if (raw is num) return raw.toDouble();
      return double.tryParse('$raw');
    }

    int? readInt(Object? raw) {
      if (raw == null) return null;
      if (raw is num) return raw.round();
      return int.tryParse('$raw');
    }

    return IdeaAnalysisRecord(
      analysisId: id,
      ideaId: (map['ideaId'] as String? ?? '').trim(),
      organisationId: (map['organisationId'] as String? ?? '').trim(),
      provider: AnalysisProviderType.parse('${map['provider'] ?? 'turnitin'}') ??
          AnalysisProviderType.turnitin,
      status: IdeaAnalysisStatus.parse('${map['status'] ?? ''}'),
      capabilities: caps,
      similarityPercent: readDouble(map['similarityPercent']),
      aiWritingPercent: readDouble(map['aiWritingPercent']),
      matchingSourceCount: readInt(map['matchingSourceCount']),
      fullReportAvailable: map['fullReportAvailable'] == true,
      failureMessage: (map['failureMessage'] as String?)?.trim(),
      createdAt: created,
      completedAt: completed,
    );
  }

  factory IdeaAnalysisRecord.fromServiceMap(Map<String, dynamic> map) {
    final String id = (map['analysisId'] as String? ?? '').trim();
    return IdeaAnalysisRecord.fromMap(id, map);
  }
}
