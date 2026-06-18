import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';

/// CSV import is available on tablet and desktop/web only — not on mobile.
abstract final class ImportPlatformSupport {
  ImportPlatformSupport._();

  static bool isSupported(BuildContext context) => !ResponsiveHelper.isMobile(context);
}
