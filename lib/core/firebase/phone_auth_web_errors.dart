import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// User-facing copy for web phone auth failures (tenant Firebase project).
abstract final class PhoneAuthWebErrors {
  PhoneAuthWebErrors._();

  static String format(Object error) {
    if (error is FirebaseAuthException) {
      return formatFirebaseAuthException(error);
    }
    return formatMessage(error.toString());
  }

  static String formatFirebaseAuthException(FirebaseAuthException e) {
    if (e.code == 'invalid-app-credential') {
      return tenantWebPhoneAuthSetupMessage(
        lead:
            'Phone sign-in could not verify this browser session for the organisation Firebase project.',
      );
    }
    final String message = (e.message ?? '').trim();
    if (message.isNotEmpty) {
      final String fromMessage = formatMessage(message);
      if (fromMessage != message) return fromMessage;
    }
    return message.isEmpty ? e.code : message;
  }

  static String formatMessage(String raw) {
    final String text = raw.trim();
    if (text.isEmpty) return text;
    final String lower = text.toLowerCase();
    if (_isHostnameOrReferrerIssue(lower)) {
      return tenantWebPhoneAuthSetupMessage();
    }
    return text;
  }

  static bool _isHostnameOrReferrerIssue(String lower) {
    return lower.contains('hostname match') ||
        lower.contains('hostname') && lower.contains('not found') ||
        lower.contains('referer') && lower.contains('blocked') ||
        lower.contains('referrer') && lower.contains('blocked') ||
        lower.contains('requests from referer') ||
        lower.contains('api key not valid') && lower.contains('referer');
  }

  /// Explains that OTP uses the **tenant** Firebase project while Hackz runs on another origin.
  static String tenantWebPhoneAuthSetupMessage({String? lead}) {
    final String origin = _currentWebOriginLabel();
    final String host = _currentWebHost();
    final String intro = lead ??
        'Phone sign-in uses your organisation\'s Firebase project, not the Hackz Control Plane project.';
    return '$intro '
        'On web, that tenant project must allow the Hackz site you are using now ($origin).\n\n'
        'In the **organisation tenant** Firebase Console (the project registered for this college):\n'
        '1. Authentication → Sign-in method → enable **Phone**.\n'
        '2. Authentication → Settings → **Authorized domains** — add `$host` '
        '(and every Hackz hosting domain you use, e.g. your Firebase Hosting or custom domain).\n'
        '3. Google Cloud Console → APIs & Services → Credentials → the **tenant web API key** '
        '→ Application restrictions → **HTTP referrers** — add `https://$host/*` '
        'and the same for your Hackz URLs (plus `http://localhost:*` for local dev).\n\n'
        'Use one consistent local origin (prefer `localhost`, not `127.0.0.1`). '
        'Then refresh Hackz and try again.';
  }

  static String _currentWebHost() {
    if (!kIsWeb) return 'your-hackz-domain';
    final String host = Uri.base.host.trim();
    return host.isEmpty ? 'your-hackz-domain' : host;
  }

  static String _currentWebOriginLabel() {
    if (!kIsWeb) return 'this browser origin';
    final Uri uri = Uri.base;
    if (uri.host.isEmpty) return 'this browser origin';
    final String port = uri.hasPort && uri.port != 80 && uri.port != 443 ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }
}
