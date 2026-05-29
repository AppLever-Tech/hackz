import 'package:flutter/material.dart';

/// Premium sectional surface used across request workspaces (faculty
/// authoring + dept admin review). Visually aligned with the dashboard card
/// language — compact padding, soft border, subtle shadow.
class RequestWorkspaceSection extends StatelessWidget {
  const RequestWorkspaceSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
    this.trailing,
    this.dense = false,
    this.tone,
  });

  final String title;
  final Widget child;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool dense;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = EdgeInsets.fromLTRB(
      dense ? 12 : 14,
      dense ? 10 : 12,
      dense ? 12 : 14,
      dense ? 10 : 14,
    );
    final Color toneColor = tone ?? const Color(0xFF6A38FF);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EAF3)),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              if (leading != null) ...<Widget>[
                leading!,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: dense ? 12 : 13,
                        fontWeight: FontWeight.w800,
                        color: toneColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
          SizedBox(height: dense ? 8 : 10),
          child,
        ],
      ),
    );
  }
}
