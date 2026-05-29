import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../models/enums/account_workspace_phase.dart';
import '../../features/user/models/user_model.dart';
import '../../utils/common_helpers.dart';
import '../../utils/firestore_utils.dart';
import '../../screens/common/dashboard_components.dart';
import 'approval_timeline_vm.dart';
import 'approval_timeline_widget.dart';
import 'registration_info_card.dart';
import 'status_hero_card.dart';
import 'support_help_card.dart';
import 'what_happens_next_card.dart';

/// Premium onboarding-style shell for non-active accounts (and future access-code flows).
class AccountStatusWorkspace extends StatefulWidget {
  const AccountStatusWorkspace({
    super.key,
    required this.user,
    required this.phase,
    required this.onSignOut,
  });

  final UserModel user;
  final AccountWorkspacePhase phase;
  final VoidCallback onSignOut;

  @override
  State<AccountStatusWorkspace> createState() => _AccountStatusWorkspaceState();
}

class _AccountStatusWorkspaceState extends State<AccountStatusWorkspace> {
  String _collegeLabel = '';
  int _refreshToken = 0;

  @override
  void initState() {
    super.initState();
    _loadCollege();
  }

  Future<void> _loadCollege() async {
    final org = await FirestoreUtils.fetchOrganization(widget.user.orgId);
    if (!mounted) return;
    setState(() {
      _collegeLabel = (org?.name ?? '').trim().isNotEmpty ? org!.name.trim() : widget.user.orgId;
    });
  }

  void _onRefresh() {
    setState(() => _refreshToken++);
    _loadCollege();
  }

  @override
  Widget build(BuildContext context) {
    final steps = ApprovalTimelineConfig.stepsFor(widget.phase);
    final deptHint = widget.user.department.trim().isEmpty ? widget.user.departmentCode : widget.user.department;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FB),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TopHeaderWidget(
                    title: 'Account status',
                    titleIcon: AppIcons.pendingUsers,
                    subtitle: 'Hackz onboarding workspace',
                    dateText: formatLongDisplayDate(DateTime.now()),
                    onRefresh: _onRefresh,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      key: ValueKey<int>(_refreshToken),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          StatusHeroCard(
                            phase: widget.phase,
                            submittedAt: widget.user.createdAt,
                            rejectionReason: widget.user.rejectionReason,
                          ),
                          const SizedBox(height: 14),
                          SectionContainer(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'Progress',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 12),
                                ApprovalTimelineWidget(steps: steps),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth < 860) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    SectionContainer(
                                      child: RegistrationInfoCard(
                                        user: widget.user,
                                        collegeName: _collegeLabel,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    SectionContainer(
                                      child: WhatHappensNextCard(phase: widget.phase),
                                    ),
                                  ],
                                );
                              }
                              return IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    Expanded(
                                      child: SectionContainer(
                                        child: RegistrationInfoCard(
                                          user: widget.user,
                                          collegeName: _collegeLabel,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: SectionContainer(
                                        child: WhatHappensNextCard(phase: widget.phase),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          SectionContainer(
                            child: SupportHelpCard(
                              departmentHint: deptHint.trim().isEmpty ? null : deptHint,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: widget.onSignOut,
                              icon: const Icon(Icons.logout),
                              label: const Text('Logout'),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
