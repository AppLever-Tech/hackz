import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../responsive/responsive_helper.dart';
import 'view_mode.dart';

/// Compact two-segment toggle for switching between list and table views.
///
/// Auto-hides on mobile (tables don't fit phones, so the scaffold forces list
/// mode there regardless of the explicit selection).
class ViewModeSwitcher extends StatelessWidget {
  const ViewModeSwitcher({
    super.key,
    required this.mode,
    required this.onChanged,
    this.height = 44,
  });

  final DataViewMode mode;
  final ValueChanged<DataViewMode> onChanged;
  final double height;

  static const Color _border = Color(0xFFD9E2F5);
  static const Color _surface = Color(0xFFFCFDFF);
  static const Color _selectedBg = Color(0xFFEEF2FF);
  static const Color _selectedFg = Color(0xFF4A67FF);
  static const Color _idleFg = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isMobile(context)) return const SizedBox.shrink();

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border, width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _segment(DataViewMode.list, AppIcons.viewList, 'List view'),
          Container(width: 1, color: _border),
          _segment(DataViewMode.table, AppIcons.viewTable, 'Table view'),
        ],
      ),
    );
  }

  Widget _segment(DataViewMode value, IconData icon, String tooltip) {
    final bool selected = value == mode;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: selected ? null : () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          color: selected ? _selectedBg : Colors.transparent,
          child: Icon(
            icon,
            size: 20,
            color: selected ? _selectedFg : _idleFg,
          ),
        ),
      ),
    );
  }
}
