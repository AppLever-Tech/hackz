import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../core/responsive/responsive_helper.dart';
import '../../screens/common/dashboard_components.dart';

/// Compact single-line access / invite code row for department admin screens.
class DepartmentAccessCodeBar extends StatelessWidget {
  const DepartmentAccessCodeBar({
    super.key,
    required this.displayCode,
    required this.onCopy,
    required this.onRegenerate,
    this.rawCode = '',
    this.copied = false,
    this.label = 'Access code',
    this.emptyHint = 'No active invite code',
  });

  final String displayCode;
  final String rawCode;
  final bool copied;
  final String label;
  final String emptyHint;
  final VoidCallback onCopy;
  final VoidCallback onRegenerate;

  bool get _hasCode => rawCode.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final bool compact = ResponsiveHelper.isMobile(context);
    final TextStyle labelStyle = TextStyle(
      fontSize: compact ? 12 : 13,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF475569),
    );
    final TextStyle codeStyle = TextStyle(
      fontSize: compact ? 14 : 15,
      fontWeight: FontWeight.w800,
      letterSpacing: _hasCode ? 0.6 : 0,
      color: _hasCode ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 8 : 9),
      decoration: kDashboardCardDecoration.copyWith(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: <Widget>[
          Text(label, style: labelStyle),
          SizedBox(width: compact ? 8 : 12),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 7 : 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(AppIcons.key, size: compact ? 16 : 18, color: const Color(0xFF64748B)),
                  SizedBox(width: compact ? 6 : 8),
                  Expanded(
                    child: Text(
                      _hasCode ? displayCode : emptyHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: codeStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: copied ? 'Copied' : 'Copy code',
            onPressed: _hasCode ? onCopy : null,
            icon: Icon(copied ? AppIcons.copied : AppIcons.copy, size: compact ? 18 : 20),
            visualDensity: VisualDensity.compact,
            constraints: BoxConstraints(minWidth: compact ? 36 : 40, minHeight: compact ? 36 : 40),
          ),
          IconButton(
            tooltip: 'Regenerate code',
            onPressed: onRegenerate,
            icon: Icon(AppIcons.refresh, size: compact ? 18 : 20),
            visualDensity: VisualDensity.compact,
            constraints: BoxConstraints(minWidth: compact ? 36 : 40, minHeight: compact ? 36 : 40),
          ),
        ],
      ),
    );
  }
}
