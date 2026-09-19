import 'package:cloud_firestore/cloud_firestore.dart';

enum AnalysisProviderType {
  turnitin,
  drillbit;

  String get label => switch (this) {
        AnalysisProviderType.turnitin => 'Turnitin',
        AnalysisProviderType.drillbit => 'DrillBit',
      };

  static AnalysisProviderType? parse(String raw) {
    final value = raw.trim().toLowerCase();
    for (final AnalysisProviderType type in AnalysisProviderType.values) {
      if (type.name == value) return type;
    }
    return null;
  }
}

enum AnalysisConnectionStatus {
  connected,
  notConfigured,
  error;

  static AnalysisConnectionStatus parse(String raw) {
    return switch (raw.trim().toLowerCase()) {
      'connected' => AnalysisConnectionStatus.connected,
      'error' => AnalysisConnectionStatus.error,
      _ => AnalysisConnectionStatus.notConfigured,
    };
  }

  String get label => switch (this) {
        AnalysisConnectionStatus.connected => 'Connected',
        AnalysisConnectionStatus.notConfigured => 'Not Configured',
        AnalysisConnectionStatus.error => 'Error',
      };
}

/// Normalized async job status for provider submissions (Phase 1 foundation).
enum AnalysisJobStatus {
  pending,
  processing,
  completed,
  failed;

  static AnalysisJobStatus parse(String raw) {
    return switch (raw.trim().toUpperCase()) {
      'PROCESSING' => AnalysisJobStatus.processing,
      'COMPLETED' => AnalysisJobStatus.completed,
      'FAILED' => AnalysisJobStatus.failed,
      _ => AnalysisJobStatus.pending,
    };
  }
}

enum AnalysisCapability {
  similarity,
  aiWriting,
  matchingSources,
  fullReport;

  String get label => switch (this) {
        AnalysisCapability.similarity => 'Similarity',
        AnalysisCapability.aiWriting => 'AI Writing',
        AnalysisCapability.matchingSources => 'Matching Sources',
        AnalysisCapability.fullReport => 'Full Report',
      };

  static AnalysisCapability? parse(String raw) {
    final normalized = raw.trim();
    for (final AnalysisCapability cap in AnalysisCapability.values) {
      if (cap.name == normalized) return cap;
    }
    return null;
  }
}

/// Non-secret provider configuration mirrored in tenant Firestore.
class AnalysisProviderPublicConfig {
  const AnalysisProviderPublicConfig({
    required this.organisationId,
    required this.provider,
    required this.enabled,
    required this.connectionStatus,
    required this.capabilities,
    this.lastVerifiedAt,
    required this.credentialsConfigured,
    this.lastError,
    this.apiBaseUrl,
    this.integrationName,
  });

  final String organisationId;
  final AnalysisProviderType provider;
  final bool enabled;
  final AnalysisConnectionStatus connectionStatus;
  final List<AnalysisCapability> capabilities;
  final DateTime? lastVerifiedAt;
  final bool credentialsConfigured;
  final String? lastError;
  final String? apiBaseUrl;
  final String? integrationName;

  factory AnalysisProviderPublicConfig.empty(String organisationId) {
    return AnalysisProviderPublicConfig(
      organisationId: organisationId,
      provider: AnalysisProviderType.turnitin,
      enabled: false,
      connectionStatus: AnalysisConnectionStatus.notConfigured,
      capabilities: const <AnalysisCapability>[],
      credentialsConfigured: false,
    );
  }

  factory AnalysisProviderPublicConfig.fromMap(String organisationId, Map<String, dynamic> map) {
    final List<AnalysisCapability> caps = <AnalysisCapability>[];
    final Object? rawCaps = map['capabilities'];
    if (rawCaps is List<dynamic>) {
      for (final Object? item in rawCaps) {
        final AnalysisCapability? cap = AnalysisCapability.parse('${item ?? ''}');
        if (cap != null) caps.add(cap);
      }
    }
    DateTime? verified;
    final Object? verifiedRaw = map['lastVerifiedAt'];
    if (verifiedRaw is Timestamp) {
      verified = verifiedRaw.toDate();
    } else if (verifiedRaw is String && verifiedRaw.isNotEmpty) {
      verified = DateTime.tryParse(verifiedRaw);
    }

    return AnalysisProviderPublicConfig(
      organisationId: organisationId,
      provider: AnalysisProviderType.parse('${map['provider'] ?? 'turnitin'}') ??
          AnalysisProviderType.turnitin,
      enabled: map['enabled'] == true,
      connectionStatus: AnalysisConnectionStatus.parse('${map['connectionStatus'] ?? ''}'),
      capabilities: caps,
      lastVerifiedAt: verified,
      credentialsConfigured: map['credentialsConfigured'] == true,
      lastError: (map['lastError'] as String?)?.trim(),
      apiBaseUrl: (map['apiBaseUrl'] as String?)?.trim(),
      integrationName: (map['integrationName'] as String?)?.trim(),
    );
  }
}
