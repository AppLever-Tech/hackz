import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../dashboard/chrome/dashboard_components.dart';
import '../../imports/imports.dart';
import '../../user/models/enums/user_role.dart';
import '../../user/models/user_model.dart';
import '../../../utils/firestore_utils.dart';

/// Coordinator workspace for Team Registration CSV import.
class TeamRegistrationScreen extends StatefulWidget {
  const TeamRegistrationScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<TeamRegistrationScreen> createState() => _TeamRegistrationScreenState();
}

class _TeamRegistrationScreenState extends State<TeamRegistrationScreen> {
  String _orgName = '';
  bool _loadingOrg = true;

  @override
  void initState() {
    super.initState();
    _loadOrg();
  }

  Future<void> _loadOrg() async {
    try {
      final org = await FirestoreUtils.fetchOrganization(widget.user.orgId);
      final String name = (org?.name ?? '').trim();
      if (!mounted) return;
      setState(() {
        _orgName = name.isEmpty ? widget.user.orgId : name;
        _loadingOrg = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _orgName = widget.user.orgId;
        _loadingOrg = false;
      });
    }
  }

  Future<void> _openImport() async {
    if (!ImportPlatformSupport.isSupported(context)) {
      FeedbackService.showInfo(
        context,
        title: 'Use a larger screen',
        message: 'Team Registration import is available on tablet and desktop.',
      );
      return;
    }
    await showTeamRegistrationImportWorkflow(
      context: context,
      actor: widget.user,
      orgName: _orgName,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (UserRole.fromCode(widget.user.role) != UserRole.coordinator) {
      return const Center(child: Text('Access denied: Coordinator only'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(18),
          decoration: kDashboardCardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8ECFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(AppIcons.teams, color: Color(0xFF4F46E5)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Team Registration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _loadingOrg
                    ? 'Load a CSV of teams, Team Leaders and Team Members. Hackz validates the full file before creating users or teams.'
                    : 'Register teams for $_orgName. One CSV includes team names, Team Leaders and Team Members. Teams stay under this college. Existing users are matched by phone; new Team Members are created only after the file passes validation. Email and department are optional — department is free text for external participants only.',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                  color: Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const <Widget>[
                  _HintChip(label: 'One row per member'),
                  _HintChip(label: 'Phone is unique'),
                  _HintChip(label: 'One Team Leader per team'),
                  _HintChip(label: 'Email optional'),
                  _HintChip(label: 'Department optional for external members'),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _loadingOrg ? null : _openImport,
                icon: const Icon(AppIcons.submissions, size: 18),
                label: const Text('Import CSV'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF334155),
        ),
      ),
    );
  }
}
