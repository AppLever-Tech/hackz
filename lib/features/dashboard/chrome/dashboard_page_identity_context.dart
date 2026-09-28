import 'package:flutter/material.dart';

import '../../../core/firebase/hackz_firebase.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/common/page_header_context_pill.dart';
import '../../../features/user/models/enums/user_role.dart';
import '../../../features/user/models/user_model.dart';
import '../../../features/user/services/user_role_labels.dart';
import '../../../utils/common_helpers.dart';

/// Session-derived identity shown under dashboard page titles (web).
class DashboardPageIdentityContext {
  const DashboardPageIdentityContext({
    required this.displayName,
    required this.roleLabel,
    required this.roleIcon,
    this.organisationName,
  });

  final String displayName;
  final String roleLabel;
  final IconData roleIcon;
  final String? organisationName;

  static DashboardPageIdentityContext fromSession({
    required UserModel user,
    List<PageHeaderContextItem> headerContextItems = const <PageHeaderContextItem>[],
  }) {
    final UserRole role = UserRole.fromCode(user.role);
    return DashboardPageIdentityContext(
      displayName: userDisplayName(user),
      roleLabel: UserRoleLabels.headerLabelFor(role),
      roleIcon: AppIcons.forUserRoleCode(user.role),
      organisationName: _resolveOrganisationName(user, headerContextItems),
    );
  }

  static String? _resolveOrganisationName(
    UserModel user,
    List<PageHeaderContextItem> headerContextItems,
  ) {
    if (HackzFirebase.isOrganisationWorkspace) {
      final String fromTenant = HackzFirebase.current.context.organisationName.trim();
      if (fromTenant.isNotEmpty) return fromTenant;
    }

    for (final PageHeaderContextItem item in headerContextItems) {
      if (item.kind != PageHeaderContextKind.organization) continue;
      final String label = item.label.trim();
      if (label.isNotEmpty) return label;
    }

    if (HackzFirebase.isTenantBound) {
      final String fromUser = user.organisationName.trim();
      if (fromUser.isNotEmpty) return fromUser;
    }

    return null;
  }

  /// Drops organisation pills duplicated on the identity row.
  List<PageHeaderContextItem> filterContextItems(List<PageHeaderContextItem> items) {
    final String? org = organisationName?.trim();
    if (org == null || org.isEmpty) return items;
    return items
        .where(
          (PageHeaderContextItem item) =>
              !(item.kind == PageHeaderContextKind.organization && item.label.trim() == org),
        )
        .toList(growable: false);
  }
}

/// Text-only username pill beside the page title.
class PageHeaderUsernamePill extends StatelessWidget {
  const PageHeaderUsernamePill({super.key, required this.label});

  final String label;

  static const EdgeInsets _padding = EdgeInsets.symmetric(horizontal: 10, vertical: 5);
  static const TextStyle _style = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: Color(0xFF64748B),
  );

  @override
  Widget build(BuildContext context) {
    final String text = label.trim();
    if (text.isEmpty) return const SizedBox.shrink();

    return Tooltip(
      message: text,
      child: Container(
        padding: _padding,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _style,
          ),
        ),
      ),
    );
  }
}

/// Role pill (icon + label) on the identity row.
class PageHeaderRolePill extends StatelessWidget {
  const PageHeaderRolePill({
    super.key,
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final String text = label.trim();
    if (text.isEmpty) return const SizedBox.shrink();

    const Color foreground = Color(0xFF334155);
    return Tooltip(
      message: text,
      child: Container(
        padding: PageHeaderContextPillStyle.padding,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: PageHeaderContextPillStyle.iconSize, color: foreground),
            const SizedBox(width: PageHeaderContextPillStyle.iconGap),
            Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: PageHeaderContextPillStyle.textStyle.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

/// Role + optional organisation directly under the page title.
class DashboardPageIdentityRow extends StatelessWidget {
  const DashboardPageIdentityRow({
    super.key,
    required this.identity,
    this.leadingIndent = 0,
  });

  final DashboardPageIdentityContext identity;
  final double leadingIndent;

  @override
  Widget build(BuildContext context) {
    final String? org = identity.organisationName?.trim();

    return Padding(
      padding: EdgeInsets.only(left: leadingIndent),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          PageHeaderRolePill(icon: identity.roleIcon, label: identity.roleLabel),
          if (org != null && org.isNotEmpty)
            Tooltip(
              message: org,
              child: PageHeaderContextPill.fromItem(PageHeaderContextItem.organization(org)),
            ),
        ],
      ),
    );
  }
}
