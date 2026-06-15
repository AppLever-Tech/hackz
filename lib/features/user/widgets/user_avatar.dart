import 'package:flutter/material.dart';

import '../../../core/ui/inputs/network_image_compat.dart';
import '../models/user_model.dart';

/// Avatar for user cards, workspace headers, and assignment rows.
///
/// Circular by default; pass [borderRadius] for a rounded-rectangle crop.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 24,
    this.fontSize,
    this.borderRadius,
    this.framed = false,
  });

  final UserModel user;
  final double radius;
  final double? fontSize;
  final BorderRadius? borderRadius;
  final bool framed;

  static const Color _initialsBackground = Color(0xFFEEF2FF);
  static const Color _initialsForeground = Color(0xFF4F46E5);
  static const Color _frameBorder = Color(0xFFE2E8F0);
  static const List<BoxShadow> _frameShadow = <BoxShadow>[
    BoxShadow(color: Color(0x140F172A), blurRadius: 20, offset: Offset(0, 8)),
  ];

  bool get _isCircular => borderRadius == null;

  BorderRadius get _clipRadius => borderRadius ?? BorderRadius.circular(radius);

  @override
  Widget build(BuildContext context) {
    final Widget core = _buildAvatarCore();
    if (!framed) return core;
    return Container(
      decoration: BoxDecoration(
        borderRadius: _clipRadius,
        border: Border.all(color: _frameBorder),
        boxShadow: _frameShadow,
      ),
      child: ClipRRect(borderRadius: _clipRadius, child: core),
    );
  }

  Widget _buildAvatarCore() {
    final String url = user.avatarUrl;
    final String initials = _initials(user.displayName);
    final double resolvedFontSize = fontSize ?? (radius * 0.72);
    final double size = radius * 2;

    Widget content;
    if (url.isEmpty) {
      content = _initialsAvatar(initials: initials, fontSize: resolvedFontSize);
    } else {
      final Widget image = NetworkImageCompat(
        url: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        logTag: 'UserAvatar',
        logContext: 'userId=${user.userId}',
        errorBuilder: (_) => _initialsAvatar(initials: initials, fontSize: resolvedFontSize),
      );
      content = _isCircular ? ClipOval(child: image) : ClipRRect(borderRadius: _clipRadius, child: image);
    }

    if (framed || !_isCircular) {
      return SizedBox(width: size, height: size, child: content);
    }
    return content;
  }

  Widget _initialsAvatar({
    required String initials,
    required double fontSize,
  }) {
    if (_isCircular && !framed) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: _initialsBackground,
        foregroundColor: _initialsForeground,
        child: Text(
          initials,
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: fontSize),
        ),
      );
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: _initialsBackground,
        borderRadius: _clipRadius,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
          color: _initialsForeground,
        ),
      ),
    );
  }

  static String _initials(String name) {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
