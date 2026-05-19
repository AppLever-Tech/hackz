import 'package:flutter/material.dart';

import '../../theme/auth_theme.dart';

enum _AuthActionVariant { primary, secondary }

/// Primary gradient or secondary outlined CTA used on auth and mobile landing screens.
class AuthActionButton extends StatelessWidget {
  const AuthActionButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.compact = false,
  }) : variant = _AuthActionVariant.primary;

  const AuthActionButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.compact = false,
  }) : variant = _AuthActionVariant.secondary;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool compact;
  final _AuthActionVariant variant;

  @override
  Widget build(BuildContext context) {
    final Widget child = isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 14 : 16,
                    fontWeight: FontWeight.w700,
                    color: variant == _AuthActionVariant.primary ? Colors.white : AuthTheme.ink,
                  ),
                ),
              ),
            ],
          );

    if (variant == _AuthActionVariant.primary) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: AuthTheme.primaryButton,
          borderRadius: BorderRadius.circular(AuthTheme.buttonRadius),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x336A38FF), blurRadius: 14, offset: Offset(0, 6)),
          ],
        ),
        child: FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            minimumSize: Size(double.infinity, compact ? 44 : AuthTheme.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AuthTheme.buttonRadius),
            ),
          ),
          child: child,
        ),
      );
    }

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, compact ? 44 : AuthTheme.buttonHeight),
        side: const BorderSide(color: AuthTheme.outline, width: 1.2),
        foregroundColor: AuthTheme.ink,
        backgroundColor: Colors.white.withValues(alpha: 0.72),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AuthTheme.buttonRadius),
        ),
      ),
      child: child,
    );
  }
}
