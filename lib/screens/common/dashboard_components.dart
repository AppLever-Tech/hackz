import 'package:flutter/material.dart';

const double _kMetricCardHeight = 108;
const double _kMetricCardPadding = 16;
const double _kMetricPrimaryCountFontSize = 32;
const double _kMetricSecondaryCountFontSize = 32;
const double _kMetricSlashFontSize = 20;
const double _kMetricIconMetricCountFontSize = 32;
const double _kMetricLabelFontSize = 13;
const double _kMetricIconBubbleSize = 42;
const double _kMetricIconBubbleIconSize = 20;
const double _kMetricInlineIconSize = 18;
const double _kMetricLabelBottomGap = 8;

/// Surface, border, and shadow shared by dashboard metric cards and section tiles.
/// Not `const`: [Border.all] is not a const factory in this SDK when used inside [BoxDecoration].
final BoxDecoration kDashboardCardDecoration = BoxDecoration(
  color: const Color(0xFFFCFDFF),
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: const Color(0xFFD9E2F5), width: 1.2),
  boxShadow: const <BoxShadow>[
    BoxShadow(color: Color(0x1A273B6A), blurRadius: 14, offset: Offset(0, 6)),
  ],
);

class SidebarWidget extends StatelessWidget {
  const SidebarWidget({
    super.key,
    required this.primaryMenus,
    required this.secondaryMenus,
    this.selectedPrimaryIndex = 0,
    this.onPrimaryMenuTap,
  });

  final List<DashboardMenuItem> primaryMenus;
  final List<DashboardMenuItem> secondaryMenus;
  final int selectedPrimaryIndex;
  final ValueChanged<int>? onPrimaryMenuTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Image.asset(
                'assets/images/hackz_logo.png',
                width: 34,
                height: 34,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              const Text(
                'HACKZ',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (int index = 0; index < primaryMenus.length; index++)
            _NavItem(
              label: primaryMenus[index].label,
              icon: primaryMenus[index].icon,
              selected: index == selectedPrimaryIndex,
              onTap: onPrimaryMenuTap == null ? null : () => onPrimaryMenuTap!(index),
            ),
          const Spacer(),
          for (final item in secondaryMenus)
            _NavItem(
              label: item.label,
              icon: item.icon,
            ),
        ],
      ),
    );
  }
}

class TopHeaderWidget extends StatelessWidget {
  const TopHeaderWidget({
    super.key,
    required this.title,
    this.titleIcon,
    required this.subtitle,
    required this.dateText,
    required this.onRefresh,
    required this.onLogout,
  });

  final String title;
  final IconData? titleIcon;
  final String subtitle;
  final String dateText;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (titleIcon != null) ...<Widget>[
                  Icon(titleIcon, size: 24, color: const Color(0xFF334155)),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ],
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            dateText,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh),
          onPressed: onRefresh,
        ),
        IconButton(
          tooltip: 'Logout',
          icon: const Icon(Icons.logout),
          onPressed: onLogout,
        ),
      ],
    );
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.iconBgColor,
    this.secondaryValue,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color iconBgColor;
  final String? secondaryValue;

  @override
  Widget build(BuildContext context) {
    return DashboardCountCard(
      value: value,
      secondaryValue: secondaryValue,
      label: label,
      icon: icon,
      iconBgColor: iconBgColor,
    );
  }
}

class DashboardCountCard extends StatelessWidget {
  const DashboardCountCard({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.iconBgColor,
    this.secondaryValue,
  });

  final String value;
  final String? secondaryValue;
  final String label;
  final IconData icon;
  final Color iconBgColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kMetricCardHeight,
      child: Container(
        padding: const EdgeInsets.all(_kMetricCardPadding),
        decoration: kDashboardCardDecoration,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (secondaryValue == null)
                    Text(
                      value,
                    style: const TextStyle(fontSize: _kMetricPrimaryCountFontSize, fontWeight: FontWeight.w700),
                    )
                  else
                    Row(
                      children: <Widget>[
                        Text(
                          value,
                        style:
                            const TextStyle(fontSize: _kMetricSecondaryCountFontSize, fontWeight: FontWeight.w700),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '/',
                          style: TextStyle(
                            fontSize: _kMetricSlashFontSize,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                          ),
                        ),
                        Text(
                          secondaryValue!,
                        style:
                            const TextStyle(fontSize: _kMetricSecondaryCountFontSize, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                const Spacer(),
                const SizedBox(height: _kMetricLabelBottomGap),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: _kMetricLabelFontSize),
                  ),
                ],
              ),
            ),
            Container(
            width: _kMetricIconBubbleSize,
            height: _kMetricIconBubbleSize,
              decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(icon, size: _kMetricIconBubbleIconSize),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardIconMetric {
  const DashboardIconMetric({
    required this.icon,
    required this.tooltip,
    required this.count,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final String count;
  final Color? color;
}

class DashboardIconMetricCard extends StatelessWidget {
  const DashboardIconMetricCard({
    super.key,
    required this.metrics,
    required this.label,
    required this.icon,
    required this.iconBgColor,
  }) : assert(metrics.length >= 1 && metrics.length <= 3, 'metrics length must be 1 to 3');

  final List<DashboardIconMetric> metrics;
  final String label;
  final IconData icon;
  final Color iconBgColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _kMetricCardHeight,
      child: Container(
        padding: const EdgeInsets.all(_kMetricCardPadding),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFDFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD9E2F5), width: 1.2),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x1A273B6A), blurRadius: 14, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: metrics
                        .map(
                          (metric) => Expanded(
                            child: Tooltip(
                              message: metric.tooltip,
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                children: <Widget>[
                                  Icon(
                                    metric.icon,
                                    size: _kMetricInlineIconSize,
                                    color: metric.color ?? const Color(0xFF475069),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      metric.count,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: _kMetricIconMetricCountFontSize,
                                        fontWeight: FontWeight.w700,
                                        color: metric.color ?? const Color(0xFF111827),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const Spacer(),
                  const SizedBox(height: _kMetricLabelBottomGap),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: _kMetricLabelFontSize),
                  ),
                ],
              ),
            ),
            Container(
              width: _kMetricIconBubbleSize,
              height: _kMetricIconBubbleSize,
              decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
              child: Icon(icon, size: _kMetricIconBubbleIconSize),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD9E2F5), width: 1.2),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x1A273B6A), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
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
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? const Color(0xFF00A7A1) : Colors.grey.shade600;
    return MouseRegion(
      cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFE8FAF9) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
