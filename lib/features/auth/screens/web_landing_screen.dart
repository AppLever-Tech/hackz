import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/auth_theme.dart';
import '../widgets/landing/landing_ecosystem_sections.dart';
import '../widgets/landing/innovation_journey_grid.dart';
import '../widgets/landing/landing_background_shell.dart';
import '../widgets/landing/landing_hero_canvas.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

/// Premium web/tablet landing — 2-column: hero + participants | journey + capabilities.
class WebLandingScreen extends StatelessWidget {
  const WebLandingScreen({super.key});

  static const double _columnGap = 24;
  static const double _leftSectionGap = 24;
  static const double _journeyToCapabilitiesGap = 16;

  void _openSignIn(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
    );
  }

  void _openSignUp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool twoColumn = ResponsiveHelper.isDesktopOrWider(context);

    final Widget hero = LandingHeroCanvas(
      onSignIn: () => _openSignIn(context),
      onSignUp: () => _openSignUp(context),
    );
    const Widget journey = InnovationJourneyGrid();
    const Widget participants = EcosystemParticipantsSection();
    const Widget capabilities = InnovationCapabilitiesSection();

    final Widget content = twoColumn
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    hero,
                    const SizedBox(height: _leftSectionGap),
                    participants,
                  ],
                ),
              ),
              const SizedBox(width: _columnGap),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    journey,
                    const SizedBox(height: _journeyToCapabilitiesGap),
                    capabilities,
                  ],
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              hero,
              const SizedBox(height: 20),
              journey,
              const SizedBox(height: _journeyToCapabilitiesGap),
              capabilities,
              const SizedBox(height: 20),
              participants,
            ],
          );

    return LandingBackgroundShell(
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AuthTheme.webLandingMaxWidth),
            child: content,
          ),
        ),
      ),
    );
  }
}
