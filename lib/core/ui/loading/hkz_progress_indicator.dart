import 'package:flutter/material.dart';

import '../../branding/hackz_brand_loading_indicator.dart';

/// Standard Hackz loading indicator (stationary H, rotating orbit).
class HkzProgressIndicator extends StatelessWidget {
  const HkzProgressIndicator({
    super.key,
    this.size = 44,
    this.strokeWidth = 3.6,
  });

  final double size;

  /// Kept for call-site compatibility; orbit animation does not use stroke width.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return HackzBrandLoadingIndicator(size: size);
  }
}
