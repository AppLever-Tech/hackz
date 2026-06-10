import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/auth_theme.dart';
import 'landing_pipeline_data.dart';

/// Role pills arranged on an orbit around the Hackz logo (no connector lines).
class RoleConstellationGrid extends StatelessWidget {
  const RoleConstellationGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 220,
      child: _RoleOrbit(),
    );
  }
}

class _RoleOrbit extends StatelessWidget {
  const _RoleOrbit();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Offset center =
            Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
        final double rx = constraints.maxWidth * 0.4;
        final double ry = constraints.maxHeight * 0.42;
        final List<LandingRoleTile> roles = LandingRoleData.roles;

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Positioned(
              left: center.dx - 36,
              top: center.dy - 36,
              child: Image.asset(
                'assets/images/hackz_logo.png',
                width: 72,
                height: 72,
                fit: BoxFit.contain,
              ),
            ),
            for (int i = 0; i < roles.length; i++)
              _positionedPill(
                center: center,
                rx: rx,
                ry: ry,
                index: i,
                total: roles.length,
                role: roles[i],
              ),
          ],
        );
      },
    );
  }

  Widget _positionedPill({
    required Offset center,
    required double rx,
    required double ry,
    required int index,
    required int total,
    required LandingRoleTile role,
  }) {
    final double angle = -math.pi / 2 + (2 * math.pi * index / total);
    final Offset pos = Offset(
      center.dx + rx * math.cos(angle),
      center.dy + ry * math.sin(angle),
    );

    return Positioned(
      left: pos.dx - _RolePill.width / 2,
      top: pos.dy - _RolePill.height / 2,
      child: _RolePill(role: role),
    );
  }
}

class _RolePill extends StatefulWidget {
  const _RolePill({required this.role});

  final LandingRoleTile role;

  static const double width = 136;
  static const double height = 40;

  @override
  State<_RolePill> createState() => _RolePillState();
}

class _RolePillState extends State<_RolePill> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(
          minWidth: _RolePill.width,
          minHeight: _RolePill.height,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _hovered ? 0.82 : 0.68),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.role.accent.withValues(alpha: _hovered ? 0.5 : 0.3),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: widget.role.accent.withValues(alpha: _hovered ? 0.22 : 0.1),
              blurRadius: _hovered ? 10 : 6,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(widget.role.icon, size: 16, color: widget.role.accent),
            const SizedBox(width: 6),
            Text(
              widget.role.title,
              textAlign: TextAlign.center,
              style: AuthTheme.cardLabelStyle.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
