import 'package:flutter/material.dart';

import '../../../core/theme/auth_theme.dart';

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
    this.prominent = false,
  }) : variant = _AuthActionVariant.primary;

  const AuthActionButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.compact = false,
    this.prominent = false,
  }) : variant = _AuthActionVariant.secondary;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool compact;
  final bool prominent;
  final _AuthActionVariant variant;

  double get _height {
    if (prominent) return 48;
    if (compact) return 44;
    return AuthTheme.buttonHeight;
  }

  double get _fontSize {
    if (prominent) return 15;
    if (compact) return 14;
    return 16;
  }

  FontWeight get _fontWeight =>
      prominent ? FontWeight.w800 : FontWeight.w700;

  double get _iconSize => prominent ? 22 : 20;

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
                Icon(icon, size: _iconSize),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: _fontSize,
                    fontWeight: _fontWeight,
                    color: variant == _AuthActionVariant.primary
                        ? Colors.white
                        : AuthTheme.ink,
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
          boxShadow: prominent
              ? const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x4D6A38FF),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Color(0x33FF8C2B),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x336A38FF),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
        ),
        child: FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            minimumSize: Size(double.infinity, _height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AuthTheme.buttonRadius),
            ),
          ),
          child: child,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AuthTheme.buttonRadius),
        boxShadow: prominent
            ? const <BoxShadow>[
                BoxShadow(
                  color: Color(0x266A38FF),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, _height),
          side: BorderSide(
            color: AuthTheme.outline,
            width: prominent ? 1.5 : 1.2,
          ),
          foregroundColor: AuthTheme.ink,
          backgroundColor: Colors.white.withValues(alpha: prominent ? 0.88 : 0.72),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AuthTheme.buttonRadius),
          ),
        ),
        child: child,
      ),
    );
  }
}
