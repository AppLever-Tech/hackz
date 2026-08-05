import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../features/user/models/user_model.dart';
import '../../../core/workspace/user_workspace_avatar.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/ui/menus/hackz_popup_menu.dart';
import '../../../features/app_metadata/widgets/show_metadata_viewer.dart';
import '../../../features/docs/services/help_navigation.dart';
import '../../../features/docs/widgets/help_action_button.dart';
import '../../../features/feedback/services/feedback_navigation.dart';
import '../../../features/org_settings/constants/org_setting_keys.dart';
import '../../../features/org_settings/services/org_settings_service.dart';
import '../../../features/user/models/enums/user_role.dart';
import '../../../core/ui/common/time_frame_filter.dart';

/// Surface, border, and shadow shared by dashboard section tiles and list cards.
/// Not `const`: [Border.all] is not a const factory in this SDK when used inside [BoxDecoration].
final BoxDecoration kDashboardCardDecoration = BoxDecoration(
  color: const Color(0xFFFCFDFF),
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: const Color(0xFFD9E2F5), width: 1.2),
  boxShadow: const <BoxShadow>[
    BoxShadow(color: Color(0x1A273B6A), blurRadius: 14, offset: Offset(0, 6)),
  ],
);

/// Shared tappable title typography for compact mobile dashboard row cards.
abstract final class MobileRowCardStyles {
  MobileRowCardStyles._();

  static const double titleFontSize = 15;
  static const FontWeight titleFontWeight = FontWeight.w800;
  static const Color titleColor = Color(0xFF1D4ED8);

  static const TextStyle title = TextStyle(
    fontSize: titleFontSize,
    fontWeight: titleFontWeight,
    color: titleColor,
    height: 1.25,
  );
}

/// Shared nav tree for desktop sidebar, tablet rail, and mobile drawer.
///
/// Brand row layout (when [showBranding] is true):
///  * expanded — `[logo] HACKZ … [chevron-left]`
///  * compact  — `[logo] [chevron-right]`
///
/// When [onToggleCollapse] is null (e.g. inside the mobile drawer), the
/// chevron is hidden and the row falls back to logo-only / logo + title.
///
/// A 1 px divider follows the brand block to separate it from the menu items.
class DashboardNavigationPanel extends StatelessWidget {
  const DashboardNavigationPanel({
    super.key,
    required this.primaryMenus,
    this.secondaryMenus = const <DashboardMenuItem>[],
    this.selectedPrimaryIndex = 0,
    this.onPrimaryMenuTap,
    this.compact = false,
    this.showBranding = true,
    this.onToggleCollapse,
  });

  final List<DashboardMenuItem> primaryMenus;
  final List<DashboardMenuItem> secondaryMenus;
  final int selectedPrimaryIndex;
  final ValueChanged<int>? onPrimaryMenuTap;
  final bool compact;
  final bool showBranding;

  /// When non-null, a chevron toggle is rendered in the brand row.
  /// `compact == true` shows `chevron-right` (expand); `false` shows
  /// `chevron-left` (collapse).
  final VoidCallback? onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 14, vertical: compact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (showBranding) ...<Widget>[
            _buildBrandRow(),
            SizedBox(height: compact ? 10 : 14),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            SizedBox(height: compact ? 10 : 14),
          ],
          for (int index = 0; index < primaryMenus.length; index++)
            _NavItem(
              label: primaryMenus[index].label,
              icon: primaryMenus[index].icon,
              selected: index == selectedPrimaryIndex,
              compact: compact,
              onTap: onPrimaryMenuTap == null ? null : () => onPrimaryMenuTap!(index),
            ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildBrandRow() {
    final Widget logo = Image.asset(
      'assets/images/hackz_logo.png',
      width: compact ? 30 : 34,
      height: compact ? 30 : 34,
      fit: BoxFit.contain,
    );

    final Widget? toggleButton = onToggleCollapse == null
        ? null
        : _BrandToggleButton(
            collapsed: compact,
            onPressed: onToggleCollapse!,
          );

    if (compact) {
      // 72 px rail (minus 8+8 horizontal padding ⇒ 56 px content). Logo + tiny
      // chevron fit on one row when a toggle is provided; otherwise center
      // the logo for visual balance.
      if (toggleButton == null) {
        return Center(child: logo);
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[logo, toggleButton],
      );
    }

    return Row(
      children: <Widget>[
        logo,
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'HACKZ',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ),
        if (toggleButton != null) toggleButton,
      ],
    );
  }
}

class _BrandToggleButton extends StatelessWidget {
  const _BrandToggleButton({
    required this.collapsed,
    required this.onPressed,
  });

  final bool collapsed;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: collapsed ? 'Expand menu' : 'Collapse menu',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        // Horizontal padding kept tight (2 px) so the compact rail's brand
        // row fits inside its 56 px content width: logo 30 + toggle 24 = 54.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Icon(
            collapsed ? AppIcons.chevronRight : AppIcons.chevronLeft,
            size: 20,
            color: const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

/// Shared page header: icon + title on the left; refresh, avatar, user pill, and
/// overflow menu on the right. Used by dashboard tabs and detail-pane overlays.
class DashboardPageHeader extends StatelessWidget {
  const DashboardPageHeader({
    super.key,
    required this.title,
    required this.user,
    required this.onLogout,
    this.titleIcon,
    this.leading,
    this.onRefresh,
    this.onUserTap,
    this.helpPageId,
  });

  final String title;
  final IconData? titleIcon;
  final Widget? leading;
  final UserModel user;
  final VoidCallback? onRefresh;
  final VoidCallback onLogout;
  final VoidCallback? onUserTap;
  final String? helpPageId;

  @override
  Widget build(BuildContext context) {
    final double titleSize = ResponsiveHelper.titleFontSize(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (leading != null) ...<Widget>[
          leading!,
          const SizedBox(width: 2),
        ],
        if (titleIcon != null) ...<Widget>[
          Icon(
            titleIcon,
            size: titleSize >= 24 ? 24 : 20,
            color: const Color(0xFF334155),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        _DashboardHeaderActions(
          user: user,
          onLogout: onLogout,
          onRefresh: onRefresh,
          onUserTap: onUserTap,
          helpPageId: helpPageId,
        ),
      ],
    );
  }
}

class _DashboardHeaderActions extends StatelessWidget {
  const _DashboardHeaderActions({
    required this.user,
    required this.onLogout,
    this.onRefresh,
    this.onUserTap,
    this.helpPageId,
  });

  final UserModel user;
  final VoidCallback onLogout;
  final VoidCallback? onRefresh;
  final VoidCallback? onUserTap;
  final String? helpPageId;

  @override
  Widget build(BuildContext context) {
    final bool compact = ResponsiveHelper.isMobile(context);
    final double iconSize = compact ? 20 : 22;
    final double avatarRadius = compact ? 14 : 16;
    final bool showFeedback = _feedbackVisibleFor(user);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (helpPageId != null)
          HelpActionButton(
            pageId: helpPageId,
            iconSize: iconSize,
          ),
        if (onRefresh != null)
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh, size: iconSize),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: onRefresh,
          ),
        UserWorkspaceAvatar(
          user: user,
          radius: avatarRadius,
          onTap: onUserTap ?? () {},
          enabled: onUserTap != null,
        ),
        SizedBox(width: compact ? 4 : 6),
        HackzPopupMenuButton(
          tooltip: 'Account',
          actions: <HackzMenuAction>[
            HackzMenuAction(
              value: HelpNavigation.overflowAction,
              icon: AppIcons.docs,
              label: 'Help',
            ),
            if (showFeedback)
              HackzMenuAction(
                value: FeedbackNavigation.overflowAction,
                icon: AppIcons.feedback,
                label: 'Feedback',
              ),
            for (final ({String value, IconData icon, String label}) item in AppMetadataMenu.menuItems)
              HackzMenuAction(value: item.value, icon: item.icon, label: item.label),
            const HackzMenuAction(
              value: 'logout',
              icon: Icons.logout_rounded,
              label: 'Logout',
              danger: true,
            ),
          ],
          dividersBefore: AppMetadataMenu.dividersBeforeLogout,
          onSelected: (String value) {
            if (value == 'logout') {
              onLogout();
              return;
            }
            if (value == HelpNavigation.overflowAction) {
              HelpNavigation.open(context, user: user);
              return;
            }
            if (value == FeedbackNavigation.overflowAction) {
              FeedbackNavigation.open(context, user: user);
              return;
            }
            AppMetadataMenu.handleSelection(context, value);
          },
          child: HackzPopupMenuOverflowTrigger(
            size: compact ? 32 : 34,
            iconSize: compact ? 18 : 20,
          ),
        ),
      ],
    );
  }

  static bool _feedbackVisibleFor(UserModel user) {
    if (UserRole.fromCode(user.role) == UserRole.sysAdmin) return true;
    final Object? raw =
        OrgSettingsService.instance.valuesSnapshot[OrgSettingKeys.enableFeedback];
    if (raw is bool) return raw;
    return true;
  }
}

/// Shared icon + title styling for dashboard section cards ([ChartCard], [SectionContainer] headers).
abstract final class DashboardCardTitleStyle {
  DashboardCardTitleStyle._();

  static const double fontSize = 16;
  static const double iconSize = 18;
  static const double iconGap = 6;
  static const Color iconColor = Color(0xFF4B5AA9);

  static const TextStyle textStyle = TextStyle(
    fontSize: fontSize,
    fontWeight: FontWeight.w700,
    height: 1.2,
    color: Color(0xFF0F172A),
  );

  /// Matches [TimeFrameFilter.barHeight] so title + filter share one row without clipping.
  static const double headerRowHeight = TimeFrameFilter.barHeight;

  static const double headerSpacing = 3;
  static const double compactBodyHeight = 168;

  /// When the card is narrower than this, stack the timeframe filter under the title.
  static const double headerStackBreakpoint = 480;

  /// Gap between title and a right-aligned [TimeFrameFilter] in [DashboardCardHeaderRow].
  static const double headerTrailingGap = 12;
}

/// Icon + title row for dashboard cards.
class DashboardCardTitle extends StatelessWidget {
  const DashboardCardTitle({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: DashboardCardTitleStyle.iconSize, color: DashboardCardTitleStyle.iconColor),
        const SizedBox(width: DashboardCardTitleStyle.iconGap),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DashboardCardTitleStyle.textStyle,
          ),
        ),
      ],
    );
  }
}

/// Title row with optional trailing control (e.g. [TimeFrameFilter]).
class DashboardCardHeaderRow extends StatelessWidget {
  const DashboardCardHeaderRow({
    super.key,
    required this.title,
    required this.icon,
    this.trailing,
    this.stackBelowWidth = DashboardCardTitleStyle.headerStackBreakpoint,
  });

  final String title;
  final IconData icon;
  final Widget? trailing;

  /// Stack [trailing] under the title when the card is narrower than this width.
  final double stackBelowWidth;

  @override
  Widget build(BuildContext context) {
    final Widget titlePart = DashboardCardTitle(title: title, icon: icon);
    if (trailing == null) {
      return titlePart;
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool stack = constraints.maxWidth < stackBelowWidth;
        final Widget alignedTrailing = _alignTrailingTimeframe(trailing!);
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              titlePart,
              const SizedBox(height: 4),
              alignedTrailing,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(child: titlePart),
            const SizedBox(width: DashboardCardTitleStyle.headerTrailingGap),
            Flexible(child: alignedTrailing),
          ],
        );
      },
    );
  }

  /// Right-aligns timeframe chips in card headers (row + stacked layouts).
  static Widget _alignTrailingTimeframe(Widget trailing) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: double.infinity,
        height: TimeFrameFilter.barHeight,
        child: trailing,
      ),
    );
  }
}

class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.trailing,
    this.headerSpacing = DashboardCardTitleStyle.headerSpacing,
  });

  static double get headerRowHeight => DashboardCardTitleStyle.headerRowHeight;

  final String title;
  final IconData? icon;
  final Widget child;
  final Widget? trailing;
  final double headerSpacing;

  @override
  Widget build(BuildContext context) {
    final Widget header = icon != null
        ? DashboardCardHeaderRow(
            title: title,
            icon: icon!,
            trailing: trailing,
          )
        : trailing == null
            ? Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DashboardCardTitleStyle.textStyle,
              )
            : DashboardCardHeaderRow(
                title: title,
                icon: AppIcons.insights,
                trailing: trailing,
              );

    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        trailing != null ? 8 : 14,
        14,
        14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E2F5), width: 1.2),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x1A273B6A), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          header,
          SizedBox(height: headerSpacing),
          child,
        ],
      ),
    );
  }
}

class SectionContainer extends StatelessWidget {
  const SectionContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: kDashboardCardDecoration.copyWith(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }
}

class OrganizationRow extends StatelessWidget {
  const OrganizationRow({
    super.key,
    required this.name,
    required this.type,
    required this.totalUsers,
    required this.activeUsers,
    required this.pendingUsers,
    required this.totalIdeas,
  });

  final String name;
  final String type;
  final int totalUsers;
  final int activeUsers;
  final int pendingUsers;
  final int totalIdeas;

  @override
  Widget build(BuildContext context) {
    final bool healthy = pendingUsers <= (activeUsers + 1);
    final Color statusColor = healthy ? Colors.green : Colors.orange;
    final String statusText = healthy ? 'Healthy' : 'Needs Attention';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '$name\n$type',
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
            ),
          ),
          _mini('Users', totalUsers),
          _mini('Active', activeUsers),
          _mini('Pending', pendingUsers),
          _mini('Ideas', totalIdeas),
          const SizedBox(width: 10),
          Row(
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(String label, int value) {
    return SizedBox(
      width: 72,
      child: Text(
        '$label\n$value',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, height: 1.4),
      ),
    );
  }
}

class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Text(text),
    );
  }
}

class DashboardMenuItem {
  const DashboardMenuItem({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    this.selected = false,
    this.compact = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? const Color(0xFF00A7A1) : Colors.grey.shade600;
    final content = Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10, vertical: compact ? 10 : 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE8FAF9) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: compact
          ? Center(child: Icon(icon, size: 20, color: color))
          : Row(
              children: <Widget>[
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
    );

    return MouseRegion(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: compact
          ? Tooltip(message: label, child: GestureDetector(onTap: onTap, child: content))
          : GestureDetector(onTap: onTap, child: content),
    );
  }
}
