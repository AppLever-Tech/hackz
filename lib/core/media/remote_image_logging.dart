import 'package:flutter/foundation.dart';

/// Consistent console logging for remote image load failures (avatars, attachments, etc.).
void logRemoteImageLoadFailure({
  required String tag,
  required String url,
  required Object error,
  String? context,
}) {
  final String suffix =
      context == null || context.isEmpty ? '' : ' $context';
  debugPrint('[$tag] Remote image load failed url=$url$suffix error=$error');
}
