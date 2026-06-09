import 'package:flutter/material.dart';

import '../../core/responsive/responsive_helper.dart';
import 'mobile_landing_screen.dart';
import 'web_landing_screen.dart';

/// Entry landing: compact mobile or premium web/tablet experience.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.useCompactLanding(context)) {
      return const MobileLandingScreen();
    }
    return const WebLandingScreen();
  }
}
