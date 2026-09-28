import 'dart:async';

import 'package:http/http.dart' as http;

import '../constants/import_constants.dart';
import 'problem_source_extract_exception.dart';

/// Fetches publicly/link-accessible Google export URLs. No OAuth or Drive scopes.
abstract final class GoogleSourceClient {
  static const Duration _timeout = Duration(seconds: 25);

  static Future<String> getText(Uri uri, {required bool allowHtml}) async {
    final http.Client client = http.Client();
    try {
      final http.Response response = await client
          .get(
            uri,
            headers: const <String, String>{
              'Accept': 'text/html,text/csv,text/plain,application/json,*/*',
              'User-Agent': 'Mozilla/5.0 (compatible; HackzImport/1.0)',
            },
          )
          .timeout(_timeout);
      return _decode(response, allowHtml: allowHtml);
    } on TimeoutException {
      throw ProblemSourceExtractException(ImportConstants.googleSourceTimeoutMessage);
    } on ProblemSourceExtractException {
      rethrow;
    } catch (_) {
      throw ProblemSourceExtractException(ImportConstants.googleSourceInaccessibleMessage);
    } finally {
      client.close();
    }
  }

  static String _decode(http.Response response, {required bool allowHtml}) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw ProblemSourceExtractException(ImportConstants.googleSourcePrivateMessage);
    }
    if (response.statusCode == 404) {
      throw ProblemSourceExtractException(ImportConstants.googleSourceInaccessibleMessage);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProblemSourceExtractException(ImportConstants.googleSourceInaccessibleMessage);
    }

    final String body = response.body.trim();
    if (body.isEmpty) {
      throw ProblemSourceExtractException(ImportConstants.googleSourceEmptyMessage);
    }
    if (_looksLikeLoginWall(body)) {
      throw ProblemSourceExtractException(ImportConstants.googleSourcePrivateMessage);
    }
    if (!allowHtml && _looksLikeHtml(body)) {
      throw ProblemSourceExtractException(ImportConstants.googleSourcePrivateMessage);
    }
    return body;
  }

  static bool _looksLikeHtml(String body) {
    final String start = body.trimLeft().toLowerCase();
    return start.startsWith('<!doctype') || start.startsWith('<html');
  }

  static bool _looksLikeLoginWall(String body) {
    final String lower = body.toLowerCase();
    return lower.contains('accounts.google.com/servicelogin') ||
        lower.contains('accounts.google.com/v3/signin') ||
        lower.contains('you need permission') ||
        lower.contains('this document is not available') ||
        lower.contains('request access');
  }
}
