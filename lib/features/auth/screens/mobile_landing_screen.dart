import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/auth_theme.dart';
import '../widgets/auth_action_button.dart';
import '../widgets/landing_brand_header.dart';
import '../widgets/landing_feature_tile.dart';
import '../widgets/mobile_landing_shell.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

/// Compact mobile/tablet landing with full-width Sign In / Sign Up actions.
class MobileLandingScreen extends StatelessWidget {
  const MobileLandingScreen({super.key});

  static const EdgeInsets _horizontal = EdgeInsets.symmetric(horizontal: 20);

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
    return MobileLandingShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: _horizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const SizedBox(height: 8),
                  const Center(child: LandingBrandHeader()),
                  const SizedBox(height: 20),
                  const LandingTitleBlock(),
                  const SizedBox(height: 24),
                  const LandingFeatureTile(
                    icon: AppIcons.teams,
                    title: 'Team Collaboration',
                    accent: Color(0xFF6A38FF),
                  ),
                  const SizedBox(height: 8),
                  const LandingFeatureTile(
                    icon: AppIcons.ideas,
                    title: 'Idea Submission',
                    accent: Color(0xFFEA580C),
                  ),
                  const SizedBox(height: 8),
                  const LandingFeatureTile(
                    icon: AppIcons.leaderboard,
                    title: 'Evaluation & Leaderboards',
                    accent: Color(0xFF0EA5E9),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Padding(
            padding: _horizontal.copyWith(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AuthActionButton.primary(
                  label: 'Sign In',
                  icon: Icons.login_rounded,
                  onPressed: () => _openSignIn(context),
                ),
                const SizedBox(height: 12),
                AuthActionButton.secondary(
                  label: 'Sign Up',
                  icon: Icons.person_add_alt_1_rounded,
                  onPressed: () => _openSignUp(context),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Hackz • Secure innovation platform',
                  textAlign: TextAlign.center,
                  style: AuthTheme.footerStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
