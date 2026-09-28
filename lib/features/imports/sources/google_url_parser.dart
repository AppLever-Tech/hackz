import '../constants/import_constants.dart';
import 'problem_source_extract_exception.dart';

enum GoogleSourceType { document, spreadsheet }

/// Parsed public Google Doc / Sheet identity. No Drive OAuth.
class GoogleSourceRef {
  const GoogleSourceRef({
    required this.type,
    required this.id,
    required this.originalUrl,
    this.gid,
    this.published = false,
  });

  final GoogleSourceType type;
  final String id;
  final String originalUrl;
  final String? gid;
  final bool published;
}

abstract final class GoogleUrlParser {
  static final RegExp _docId = RegExp(
    r'docs\.google\.com/document(?:/u/\d+)?/d/(?:e/)?([a-zA-Z0-9_-]+)',
    caseSensitive: false,
  );
  static final RegExp _sheetId = RegExp(
    r'docs\.google\.com/spreadsheets(?:/u/\d+)?/d/(?:e/)?([a-zA-Z0-9_-]+)',
    caseSensitive: false,
  );
  static final RegExp _gid = RegExp(r'[?#&]gid=([0-9]+)|[#&]gid=([0-9]+)', caseSensitive: false);

  static GoogleSourceRef parse(String raw, {GoogleSourceType? expected}) {
    final String url = raw.trim();
    if (url.isEmpty) {
      throw ProblemSourceExtractException(ImportConstants.invalidGoogleUrlMessage);
    }

    final Uri? uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) {
      throw ProblemSourceExtractException(ImportConstants.invalidGoogleUrlMessage);
    }

    final String host = uri.host.toLowerCase();
    if (!host.contains('google.com') && !host.contains('googleusercontent.com')) {
      throw ProblemSourceExtractException(ImportConstants.unsupportedGoogleUrlMessage);
    }

    final Match? docMatch = _docId.firstMatch(url);
    final Match? sheetMatch = _sheetId.firstMatch(url);

    if (docMatch != null && sheetMatch == null) {
      if (expected == GoogleSourceType.spreadsheet) {
        throw ProblemSourceExtractException(ImportConstants.googleSheetExpectedMessage);
      }
      return GoogleSourceRef(
        type: GoogleSourceType.document,
        id: docMatch.group(1)!,
        originalUrl: url,
        published: url.contains('/d/e/'),
      );
    }

    if (sheetMatch != null) {
      if (expected == GoogleSourceType.document) {
        throw ProblemSourceExtractException(ImportConstants.googleDocExpectedMessage);
      }
      return GoogleSourceRef(
        type: GoogleSourceType.spreadsheet,
        id: sheetMatch.group(1)!,
        originalUrl: url,
        gid: _parseGid(url) ?? uri.queryParameters['gid'],
        published: url.contains('/d/e/'),
      );
    }

    throw ProblemSourceExtractException(ImportConstants.unsupportedGoogleUrlMessage);
  }

  static String? _parseGid(String url) {
    final Match? match = _gid.firstMatch(url);
    return match?.group(1) ?? match?.group(2);
  }
}
