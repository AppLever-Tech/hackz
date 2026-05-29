import 'package:flutter/material.dart';

import '../../core/theme/auth_theme.dart';
import '../../widgets/auth/auth_action_button.dart';
import '../../widgets/auth/landing_brand_header.dart';
import '../../widgets/auth/mobile_landing_shell.dart';

/// Full-page auth flow layout: landing gradient, logo header, scrollable form, pinned CTAs.
class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.formContent,
    required this.nextLabel,
    required this.onNext,
    required this.onCancel,
    this.isLoading = false,
    this.extraContent,
    this.titleFontSize = 28,
    this.actionsInRow = true,
    this.logoHeight = 100,
  });

  final String title;
  final String? subtitle;
  final Widget formContent;
  final String nextLabel;
  final VoidCallback? onNext;
  final VoidCallback onCancel;
  final bool isLoading;
  final Widget? extraContent;
  final double titleFontSize;
  final bool actionsInRow;
  final double logoHeight;

  @override
  Widget build(BuildContext context) {
    return MobileLandingShell(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool useRowActions =
              actionsInRow && constraints.maxWidth >= 480;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: AuthTheme.pagePadding.copyWith(top: 8, bottom: 16),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AuthTheme.maxContentWidth,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Center(
                            child: LandingBrandHeader(logoHeight: logoHeight),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: AuthTheme.flowTitleStyle.copyWith(
                              fontSize: titleFontSize,
                            ),
                          ),
                          if (subtitle != null &&
                              subtitle!.trim().isNotEmpty) ...<Widget>[
                            const SizedBox(height: 8),
                            Text(
                              subtitle!,
                              textAlign: TextAlign.center,
                              style: AuthTheme.subtitleStyle,
                            ),
                          ],
                          const SizedBox(height: 22),
                          formContent,
                          if (extraContent != null) ...<Widget>[
                            const SizedBox(height: 16),
                            extraContent!,
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: AuthTheme.pagePadding.copyWith(bottom: 8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AuthTheme.maxContentWidth,
                    ),
                    child: useRowActions
                        ? Row(
                            children: <Widget>[
                              Expanded(
                                child: AuthActionButton.primary(
                                  label: nextLabel,
                                  onPressed: onNext,
                                  isLoading: isLoading,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: AuthActionButton.secondary(
                                  label: 'Cancel',
                                  onPressed: onCancel,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              AuthActionButton.primary(
                                label: nextLabel,
                                onPressed: onNext,
                                isLoading: isLoading,
                              ),
                              const SizedBox(height: 10),
                              AuthActionButton.secondary(
                                label: 'Cancel',
                                onPressed: onCancel,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
