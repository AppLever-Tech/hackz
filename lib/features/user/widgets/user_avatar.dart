import 'package:flutter/material.dart';

import '../../../shared/inputs/network_image_compat.dart';
import '../models/user_model.dart';

/// Circular avatar for user cards, workspace headers, and assignment rows.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 24,
    this.fontSize,
  });

  final UserModel user;
  final double radius;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final String url = user.avatarUrl;
    final String initials = _initials(user.displayName);
    final double resolvedFontSize = fontSize ?? (radius * 0.72);

    if (url.isEmpty) {
      return _initialsAvatar(initials: initials, fontSize: resolvedFontSize);
    }

    return ClipOval(
      child: NetworkImageCompat(
        url: url,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        logTag: 'UserAvatar',
        logContext: 'userId=${user.userId}',
        errorBuilder: (_) =>
            _initialsAvatar(initials: initials, fontSize: resolvedFontSize),
      ),
    );
  }

  Widget _initialsAvatar({
    required String initials,
    required double fontSize,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFEEF2FF),
      foregroundColor: const Color(0xFF4F46E5),
      child: Text(
        initials,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
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
