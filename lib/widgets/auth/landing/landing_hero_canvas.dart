import 'package:flutter/material.dart';

import '../../../responsive/responsive_helper.dart';
import '../../../core/theme/auth_theme.dart';
import '../auth_action_button.dart';

/// Hero copy and auth CTAs for web/tablet landing (left column).
class LandingHeroCanvas extends StatelessWidget {
  const LandingHeroCanvas({
    super.key,
    required this.onSignIn,
    required this.onSignUp,
  });

  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    final bool stackButtons =
        !ResponsiveHelper.isDesktopOrWider(context) ||
        MediaQuery.sizeOf(context).width < 520;

    return _BrandColumn(
      onSignIn: onSignIn,
      onSignUp: onSignUp,
      stackButtons: stackButtons,
    );
  }
}

class _BrandColumn extends StatelessWidget {
  const _BrandColumn({
    required this.onSignIn,
    required this.onSignUp,
    required this.stackButtons,
  });

  final VoidCallback onSignIn;
  final VoidCallback onSignUp;
  final bool stackButtons;

  static const double _heroButtonWidth = 200;

  @override
  Widget build(BuildContext context) {
    final double logoHeight =
        ResponsiveHelper.isTablet(context) ? 112 : 132;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: Image.asset(
            'assets/images/hackz_logo.png',
            height: logoHeight,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              const Text(
                'Innovation Pipeline',
                textAlign: TextAlign.right,
                style: AuthTheme.heroHeadlineStyle,
              ),
              const SizedBox(height: 4),
              const Text(
                'From Idea to Impact',
                textAlign: TextAlign.right,
                style: AuthTheme.heroHeadlineStyle,
              ),
              const SizedBox(height: 12),
              const Text(
                'A structured ecosystem for innovation, research, product development, and entrepreneurship.',
                textAlign: TextAlign.right,
                style: AuthTheme.heroLeadStyle,
              ),
              const SizedBox(height: 18),
              const Text(
                'Start Building the Next Innovation',
                textAlign: TextAlign.right,
                style: AuthTheme.heroLeadStyle,
              ),
              const SizedBox(height: 14),
              if (stackButtons) ...<Widget>[
                SizedBox(
                  width: _heroButtonWidth,
                  child: AuthActionButton.primary(
                    label: 'Sign In',
                    icon: Icons.login_rounded,
                    prominent: true,
                    onPressed: onSignIn,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: _heroButtonWidth,
                  child: AuthActionButton.secondary(
                    label: 'Sign Up',
                    icon: Icons.person_add_alt_1_rounded,
                    prominent: true,
                    onPressed: onSignUp,
                  ),
                ),
              ] else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      width: _heroButtonWidth,
                      child: AuthActionButton.primary(
                        label: 'Sign In',
                        icon: Icons.login_rounded,
                        prominent: true,
                        onPressed: onSignIn,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: _heroButtonWidth,
                      child: AuthActionButton.secondary(
                        label: 'Sign Up',
                        icon: Icons.person_add_alt_1_rounded,
                        prominent: true,
                        onPressed: onSignUp,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
