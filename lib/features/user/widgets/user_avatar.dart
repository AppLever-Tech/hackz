import 'package:flutter/material.dart';

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

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFEEF2FF),
      foregroundColor: const Color(0xFF4F46E5),
      backgroundImage: url.isNotEmpty ? NetworkImage(url) : null,
      child: url.isEmpty
          ? Text(
              initials,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: fontSize ?? (radius * 0.72),
              ),
            )
          : null,
    );
  }

  static String _initials(String name) {
    final List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}
