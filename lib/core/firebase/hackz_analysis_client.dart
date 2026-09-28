import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../features/analysis/models/analysis_provider_models.dart';
import '../../features/analysis/models/idea_analysis_record.dart';
import 'hackz_analysis_identity.dart';
import 'hackz_firebase.dart';

class HackzAnalysisException implements Exception {
  const HackzAnalysisException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => message;
}

abstract final class HackzAnalysisClient {
  HackzAnalysisClient._();

  static Future<AnalysisProviderPublicConfig> saveProviderCredentials({
    required String organisationId,
    required AnalysisProviderType provider,
    required Map<String, String> credentials,
    bool enabled = true,
  }) async {
    final Map<String, dynamic> body = await _post(
      '/save-provider-credentials',
      <String, dynamic>{
        'organisationId': organisationId,
        'provider': provider.name,
        'enabled': enabled,
        'credentials': credentials,
      },
      missingTokenMessage: 'Sign in as College Admin to save analysis credentials.',
    );
    return AnalysisProviderPublicConfig.fromMap(
      organisationId,
      (body['config'] as Map<String, dynamic>?) ?? body,
    );
  }

  static Future<({bool ok, String message, AnalysisProviderPublicConfig config})> testConnection({
    required String organisationId,
    required AnalysisProviderType provider,
    Map<String, String>? credentials,
  }) async {
    final Map<String, dynamic> body = await _postAllowFailure(
      '/test-connection',
      <String, dynamic>{
        'organisationId': organisationId,
        'provider': provider.name,
        if (credentials != null) 'credentials': credentials,
      },
      missingTokenMessage: 'Sign in as College Admin to test the analysis connection.',
    );
    return (
      ok: body['ok'] == true,
      message: (body['message'] as String? ?? '').trim(),
      config: AnalysisProviderPublicConfig.fromMap(
        organisationId,
        (body['config'] as Map<String, dynamic>?) ?? body,
      ),
    );
  }

  static Future<void> clearProviderCredentials({required String organisationId}) async {
    await _post(
      '/clear-provider-credentials',
      <String, dynamic>{'organisationId': organisationId},
      missingTokenMessage: 'Sign in as College Admin to remove analysis credentials.',
    );
  }

  static Future<IdeaAnalysisRecord> runIdeaAnalysis({
    required String organisationId,
    required String ideaId,
  }) async {
    final Map<String, dynamic> body = await _post(
      '/run-idea-analysis',
      <String, dynamic>{
        'organisationId': organisationId,
        'ideaId': ideaId,
      },
      missingTokenMessage: 'Sign in to run originality analysis.',
    );
    final Object? raw = body['analysis'];
    if (raw is! Map<String, dynamic>) {
      throw const HackzAnalysisException('INVALID_RESPONSE', 'Analysis service returned an invalid response.');
    }
    return IdeaAnalysisRecord.fromServiceMap(raw);
  }

  static Future<IdeaAnalysisRecord> refreshIdeaAnalysis({
    required String organisationId,
    required String analysisId,
  }) async {
    final Map<String, dynamic> body = await _post(
      '/refresh-idea-analysis',
      <String, dynamic>{
        'organisationId': organisationId,
        'analysisId': analysisId,
      },
      missingTokenMessage: 'Sign in to refresh analysis status.',
    );
    final Object? raw = body['analysis'];
    if (raw is! Map<String, dynamic>) {
      throw const HackzAnalysisException('INVALID_RESPONSE', 'Analysis service returned an invalid response.');
    }
    return IdeaAnalysisRecord.fromServiceMap(raw);
  }

  static Future<IdeaAnalysisRecord?> getLatestIdeaAnalysis({
    required String organisationId,
    required String ideaId,
  }) async {
    final Map<String, dynamic> body = await _post(
      '/get-latest-idea-analysis',
      <String, dynamic>{
        'organisationId': organisationId,
        'ideaId': ideaId,
      },
      missingTokenMessage: 'Sign in to load analysis results.',
    );
    final Object? raw = body['analysis'];
    if (raw == null) return null;
    if (raw is! Map<String, dynamic>) {
      throw const HackzAnalysisException('INVALID_RESPONSE', 'Analysis service returned an invalid response.');
    }
    return IdeaAnalysisRecord.fromServiceMap(raw);
  }

  static Future<String> getIdeaAnalysisReportUrl({
    required String organisationId,
    required String analysisId,
  }) async {
    final Map<String, dynamic> body = await _post(
      '/get-idea-analysis-report',
      <String, dynamic>{
        'organisationId': organisationId,
        'analysisId': analysisId,
      },
      missingTokenMessage: 'Sign in to open the full report.',
    );
    final String url = (body['reportViewerUrl'] as String? ?? '').trim();
    if (url.isEmpty) {
      throw const HackzAnalysisException('NOT_AVAILABLE', 'Full report is not available.');
    }
    return url;
  }

  static Future<Map<String, dynamic>> _postAllowFailure(
    String path,
    Map<String, dynamic> payload, {
    required String missingTokenMessage,
  }) async {
    return _postInternal(path, payload, missingTokenMessage: missingTokenMessage, allowFailure: true);
  }

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> payload, {
    required String missingTokenMessage,
  }) async {
    return _postInternal(path, payload, missingTokenMessage: missingTokenMessage, allowFailure: false);
  }

  static Future<Map<String, dynamic>> _postInternal(
    String path,
    Map<String, dynamic> payload, {
    required String missingTokenMessage,
    required bool allowFailure,
  }) async {
    final HackzAnalysisIdentity identity = await HackzAnalysisIdentity.load();
    final String base = identity.invokeUrl.replaceAll(RegExp(r'/$'), '');
    if (base.isEmpty) {
      throw const HackzAnalysisException(
        'ANALYSIS_SERVICE_UNAVAILABLE',
        'The analysis service URL is not configured. Set hkzAnalysisConfig/hackz.invokeUrl on the Control Plane.',
      );
    }

    final String? token = await HackzFirebase.sessionAuth.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      throw HackzAnalysisException('UNAUTHORIZED', missingTokenMessage);
    }

    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$base$path'),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
    } catch (_) {
      throw const HackzAnalysisException(
        'ANALYSIS_SERVICE_UNAVAILABLE',
        'Unable to reach the analysis service.',
      );
    }

    Map<String, dynamic> body = <String, dynamic>{};
    try {
      final Object? decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}

    if (body['ok'] == true ||
        body.containsKey('config') ||
        body.containsKey('analysis') ||
        body.containsKey('reportViewerUrl') ||
        (allowFailure && body.containsKey('message'))) {
      return body;
    }

    throw HackzAnalysisException(
      (body['code'] as String? ?? 'REQUEST_FAILED').trim(),
      (body['message'] as String? ?? 'Analysis request failed.').trim(),
    );
  }
}
