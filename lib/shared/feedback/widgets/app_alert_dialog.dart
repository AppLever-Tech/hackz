import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../widgets/loading/hkz_loading_theme.dart';
import '../enums/app_alert_type.dart';
import '../models/app_alert_action.dart';

class AppAlertDialog extends StatelessWidget {
  const AppAlertDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    required this.actions,
  });

  final AppAlertType type;
  final String title;
  final String message;
  final List<AppAlertAction> actions;

  static const Duration enterDuration = Duration(milliseconds: 220);
  static const Duration exitDuration = Duration(milliseconds: 180);

  @override
  Widget build(BuildContext context) {
    final _AlertVisuals visuals = _AlertVisuals.resolve(type);
    final double width = HkzLoadingTheme.cardWidth(context);
    final bool isMobile = MediaQuery.sizeOf(context).width < 600;
    return Center(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, isMobile ? 24 : 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
            child: Container(
              width: width,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: visuals.border),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0x1A273B6A),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: visuals.iconBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(visuals.icon, color: visuals.accent, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: HkzLoadingTheme.titleStyle(context).copyWith(
                            fontSize: 15.5,
                            color: const Color(0xFF0F172A),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    style: HkzLoadingTheme.messageStyle.copyWith(
                      fontSize: 12.8,
                      color: const Color(0xFF475569),
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 6,
                    children: actions.map((AppAlertAction action) => _buildAction(context, action)).toList(growable: false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAction(BuildContext context, AppAlertAction action) {
    if (action.primary) {
      final Color bg = action.danger ? const Color(0xFFDC2626) : const Color(0xFF6A38FF);
      return FilledButton.icon(
        onPressed: action.onPressed,
        icon: action.icon == null ? const SizedBox.shrink() : Icon(action.icon, size: 16),
        label: Text(action.label),
        style: FilledButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          minimumSize: const Size(84, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: action.onPressed,
      icon: action.icon == null ? const SizedBox.shrink() : Icon(action.icon, size: 16),
      label: Text(action.label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF334155),
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        minimumSize: const Size(84, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _AlertVisuals {
  const _AlertVisuals({
    required this.icon,
    required this.accent,
    required this.iconBg,
    required this.border,
    required this.glow,
  });

  final IconData icon;
  final Color accent;
  final Color iconBg;
  final Color border;
  final Color glow;

  static _AlertVisuals resolve(AppAlertType type) {
    return switch (type) {
      AppAlertType.success => const _AlertVisuals(
          icon: Icons.check_circle_rounded,
          accent: Color(0xFF22C55E),
          iconBg: Color(0x1A22C55E),
          border: Color(0x5534D399),
          glow: Color(0x3322C55E),
        ),
      AppAlertType.error => const _AlertVisuals(
          icon: Icons.error_rounded,
          accent: Color(0xFFF87171),
          iconBg: Color(0x1AF87171),
          border: Color(0x55F87171),
          glow: Color(0x33F87171),
        ),
      AppAlertType.warning => const _AlertVisuals(
          icon: Icons.warning_amber_rounded,
          accent: Color(0xFFF59E0B),
          iconBg: Color(0x1AF59E0B),
          border: Color(0x55F59E0B),
          glow: Color(0x33F59E0B),
        ),
      AppAlertType.info => const _AlertVisuals(
          icon: Icons.info_rounded,
          accent: Color(0xFF60A5FA),
          iconBg: Color(0x1A60A5FA),
          border: Color(0x5560A5FA),
          glow: Color(0x3360A5FA),
        ),
      AppAlertType.confirmation => const _AlertVisuals(
          icon: Icons.help_rounded,
          accent: Color(0xFFA78BFA),
          iconBg: Color(0x1AA78BFA),
          border: Color(0x55A78BFA),
          glow: Color(0x33A78BFA),
        ),
    };
  }
}

