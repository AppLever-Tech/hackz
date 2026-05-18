import 'package:flutter/material.dart';

import '../../responsive/responsive_helper.dart';
import 'desktop_landing_view.dart';
import 'mobile_landing_screen.dart';

/// Entry landing: compact mobile/tablet experience or desktop hero image.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.useCompactLanding(context)) {
      return const MobileLandingScreen();
    }
    return const DesktopLandingView();
  }
}
