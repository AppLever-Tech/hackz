import 'package:flutter/material.dart';
import 'package:url_launcher/link.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/ui/buttons/hover_icon_action_button.dart';
import '../../../../core/ui/inputs/network_image_compat.dart';
import '../../../../core/responsive/responsive_helper.dart';
import '../../../../features/organization/models/organization_model.dart';
import '../../../../features/user/models/user_model.dart';
import '../../chrome/dashboard_components.dart';
import '../../sysadmin/screens/organization_dialog.dart';
import '../../../../utils/firestore_utils.dart';

class CollegeOverviewCard extends StatefulWidget {
  const CollegeOverviewCard({
    super.key,
    required this.user,
    required this.organization,
  });

  final UserModel user;
  final OrganizationModel? organization;

  @override
  State<CollegeOverviewCard> createState() => _CollegeOverviewCardState();
}

class _CollegeOverviewCardState extends State<CollegeOverviewCard> {
  OrganizationModel? _org;

  @override
  void initState() {
    super.initState();
    _org = widget.organization;
  }

  @override
  void didUpdateWidget(covariant CollegeOverviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organization != widget.organization) {
      _org = widget.organization;
    }
  }

  Future<void> _edit() async {
    final OrganizationModel? current = _org;
    if (current == null) return;
    final bool saved = await showOrganizationDialog(
      context: context,
      initialOrganization: current,
    );
    if (!saved || !mounted) return;
    final OrganizationModel? next = await FirestoreUtils.fetchOrganization(
      widget.user.orgId,
      preferServer: true,
    );
    if (!mounted) return;
    setState(() => _org = next ?? current);
  }

  @override
  Widget build(BuildContext context) {
    final OrganizationModel? org = _org;
    final String name = _collegeDisplayName(org, widget.user);
    final bool mobile = ResponsiveHelper.isMobile(context);

    final Widget identity = mobile
        ? _IdentityStack(org: org, name: name)
        : _IdentityRow(org: org, name: name);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget body = constraints.maxHeight.isFinite
            ? SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: identity,
              )
            : identity;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Expanded(
                  child: DashboardCardTitle(
                    title: 'College Overview',
                    icon: AppIcons.organizations,
                  ),
                ),
                if (org != null)
                  HoverIconActionButton(
                    icon: AppIcons.edit,
                    tooltip: 'Edit organization',
                    onTap: _edit,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (constraints.maxHeight.isFinite) Expanded(child: body) else body,
          ],
        );
      },
    );
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({required this.org, required this.name});

  final OrganizationModel? org;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _CollegeLogoFrame(org: org, name: name),
        const SizedBox(width: 18),
        Expanded(child: _CollegeDetailsColumn(org: org, name: name)),
      ],
    );
  }
}

class _IdentityStack extends StatelessWidget {
  const _IdentityStack({required this.org, required this.name});

  final OrganizationModel? org;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(child: _CollegeLogoFrame(org: org, name: name)),
        const SizedBox(height: 14),
        _CollegeDetailsColumn(org: org, name: name),
      ],
    );
  }
}

class _CollegeLogoFrame extends StatelessWidget {
  const _CollegeLogoFrame({required this.org, required this.name});

  final OrganizationModel? org;
  final String name;

  static const double _frameSize = 96;

  @override
  Widget build(BuildContext context) {
    final String url = org?.avatarUrl.trim() ?? '';
    return Container(
      width: _frameSize,
      height: _frameSize,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      alignment: Alignment.center,
      child: url.isEmpty
          ? _NameFallback(name: name)
          : NetworkImageCompat(
              url: url,
              width: _frameSize - 20,
              height: _frameSize - 20,
              fit: BoxFit.contain,
              logTag: 'CollegeOverviewLogo',
              errorBuilder: (_) => _NameFallback(name: name),
            ),
    );
  }
}

class _NameFallback extends StatelessWidget {
  const _NameFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final String trimmed = name.trim();
    final String initial = trimmed.isEmpty ? 'C' : trimmed.substring(0, 1).toUpperCase();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          initial,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E3A5F),
            height: 1,
          ),
        ),
        if (trimmed.isNotEmpty) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            trimmed,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _CollegeDetailsColumn extends StatelessWidget {
  const _CollegeDetailsColumn({required this.org, required this.name});

  final OrganizationModel? org;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        _DetailLine(
          icon: AppIcons.orgType,
          text: org?.type.displayName ?? 'College',
        ),
        _DetailLine(
          icon: AppIcons.address,
          text: org?.address.isNotEmpty == true ? org!.address : '—',
          multiline: true,
        ),
        _WebsiteLine(website: org?.website ?? ''),
        _DetailLine(
          icon: AppIcons.phone,
          text: org?.contact.isNotEmpty == true ? org!.contact : '—',
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.text,
    this.multiline = false,
  });

  final IconData icon;
  final String text;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 15, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: multiline ? 3 : 1,
              overflow: multiline ? TextOverflow.visible : TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebsiteLine extends StatelessWidget {
  const _WebsiteLine({required this.website});

  final String website;

  @override
  Widget build(BuildContext context) {
    final Uri? uri = _parseWebsiteUri(website);
    final String display = website.trim().isEmpty ? '—' : website.trim();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: <Widget>[
          const Icon(AppIcons.website, size: 15, color: Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: uri == null
                ? Text(
                    display,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  )
                : Link(
                    uri: uri,
                    target: LinkTarget.blank,
                    builder: (BuildContext context, Future<void> Function()? followLink) {
                      return InkWell(
                        onTap: followLink,
                        child: Text(
                          display,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

String _collegeDisplayName(OrganizationModel? org, UserModel user) {
  final String fromOrg = org?.name.trim() ?? '';
  if (fromOrg.isNotEmpty) return fromOrg;
  final String fromUser = user.organisationName.trim();
  if (fromUser.isNotEmpty) return fromUser;
  return user.orgId.trim();
}

Uri? _parseWebsiteUri(String website) {
  final normalized = website.trim();
  if (normalized.isEmpty || normalized == '-') return null;
  final withScheme = normalized.startsWith(RegExp(r'https?://'))
      ? normalized
      : 'https://$normalized';
  return Uri.tryParse(withScheme);
}
