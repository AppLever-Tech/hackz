import 'package:flutter/material.dart';

import '../../models/enums/user_role.dart';
import '../../models/attachment_model.dart';
import '../../models/payment_model.dart';
import '../../models/user_model.dart';
import '../../utils/attachment_service.dart';
import '../../utils/firestore_utils.dart';
import '../../utils/idea_role_config.dart';
import 'coordinator_payment_card.dart';
import '../common/dashboard_components.dart';
import '../common/dashboard_page_template.dart';
import '../common/leaderboard_showcase_screen.dart';
import '../common/ideas_list_screen.dart';
import '../../widgets/attachment_viewer.dart';

class CoordinatorDashboard extends StatelessWidget {
  const CoordinatorDashboard({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    if (UserRole.fromCode(user.role) != UserRole.coordinator) {
      return const Scaffold(body: Center(child: Text('Access denied: Coordinator only')));
    }
    return DashboardPageTemplate(
      user: user,
      bodyBuilder: (_, int refreshToken, int selectedMenuIndex) {
        if (selectedMenuIndex == 1) {
          return _CoordinatorPaymentsView(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        if (selectedMenuIndex == 2) {
          return IdeasListScreen(
            key: ValueKey<int>(refreshToken),
            currentUser: user,
            config: IdeaRoleConfig.configFor(UserRole.coordinator, user),
          );
        }
        if (selectedMenuIndex == 3) {
          return LeaderboardShowcaseScreen(
            key: ValueKey<int>(refreshToken),
            user: user,
          );
        }
        return _CoordinatorSummaryView(
          key: ValueKey<int>(refreshToken),
          user: user,
        );
      },
    );
  }
}

class _CoordinatorSummaryView extends StatelessWidget {
  const _CoordinatorSummaryView({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PaymentModel>>(
      future: FirestoreUtils.getPaymentsByOrg(user.orgId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load payments: ${snapshot.error}');
        }
        final payments = _scopePayments(snapshot.data ?? <PaymentModel>[]);
        final pending = payments.where((p) => p.status == PaymentRecordStatus.pending).length;
        final verified = payments.where((p) => p.status == PaymentRecordStatus.verified).length;
        final rejected = payments.where((p) => p.status == PaymentRecordStatus.rejected).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: SummaryCard(
                    value: '$pending',
                    label: 'Pending Payments',
                    icon: Icons.pending_actions_outlined,
                    iconBgColor: const Color(0xFFFFF4E8),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SummaryCard(
                    value: '$verified',
                    label: 'Verified',
                    icon: Icons.verified_outlined,
                    iconBgColor: const Color(0xFFE8FAF1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SummaryCard(
                    value: '$rejected',
                    label: 'Rejected',
                    icon: Icons.cancel_outlined,
                    iconBgColor: const Color(0xFFFDECEC),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SectionContainer(
              child: Text(
                'Use Payment Verification in the left menu to review pending uploads.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        );
      },
    );
  }

  List<PaymentModel> _scopePayments(List<PaymentModel> all) {
    final dep = user.departmentCode.trim().toUpperCase();
    if (dep.isEmpty) return all;
    return all.where((p) => p.departmentCode.trim().toUpperCase() == dep).toList(growable: false);
  }
}

class _CoordinatorPaymentsView extends StatefulWidget {
  const _CoordinatorPaymentsView({super.key, required this.user});

  final UserModel user;

  @override
  State<_CoordinatorPaymentsView> createState() => _CoordinatorPaymentsViewState();
}

class _CoordinatorPaymentsViewState extends State<_CoordinatorPaymentsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<_CoordinatorPaymentsData> _load() async {
    final payments = FirestoreUtils.getPaymentsByOrg(widget.user.orgId);
    final teams = FirestoreUtils.getTeamNamesByOrg(widget.user.orgId);
    final results = await Future.wait<dynamic>(<Future<dynamic>>[payments, teams]);
    var list = results[0] as List<PaymentModel>;
    list = _scopePayments(list);
    final teamById = results[1] as Map<String, String>;
    final studentIds = list.map((p) => p.paidByStudentId).where((e) => e.isNotEmpty).toSet();
    final names = <String, String>{};
    for (final id in studentIds) {
      final u = await FirestoreUtils.fetchUser(id);
      names[id] = u == null ? id : '${u.firstName} ${u.lastName}'.trim().isEmpty ? id : '${u.firstName} ${u.lastName}'.trim();
    }
    return _CoordinatorPaymentsData(
      payments: list,
      teamNameById: teamById,
      studentNameById: names,
    );
  }

  List<PaymentModel> _scopePayments(List<PaymentModel> all) {
    final dep = widget.user.departmentCode.trim().toUpperCase();
    if (dep.isEmpty) return all;
    return all.where((p) => p.departmentCode.trim().toUpperCase() == dep).toList(growable: false);
  }

  Future<void> _viewShot(PaymentModel payment) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => FutureBuilder<List<AttachmentModel>>(
        future: AttachmentService.fetchActiveAttachments(
          entityType: AttachmentEntityType.payment,
          entityId: payment.paymentId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              title: Text('Payment attachments'),
              content: SizedBox(width: 520, height: 160, child: Center(child: CircularProgressIndicator())),
            );
          }
          final attachments = snapshot.data ?? const <AttachmentModel>[];
          if (attachments.isNotEmpty) {
            return AttachmentViewerDialog(
              title: 'Payment attachments',
              attachments: attachments,
            );
          }
          final url = payment.paymentProofUrl.trim();
          return AlertDialog(
            title: const Text('Payment screenshot'),
            content: SizedBox(
              width: 520,
              child: url.isEmpty ? const Text('No payment proof uploaded.') : SelectableText(url),
            ),
            actions: <Widget>[
              OutlinedButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
            ],
          );
        },
      ),
    );
  }

  Future<void> _approve(PaymentModel p) async {
    await FirestoreUtils.verifyIdeaPayment(
      paymentId: p.paymentId,
      coordinatorId: widget.user.userId,
    );
    if (mounted) setState(() {});
  }

  Future<void> _reject(PaymentModel p) async {
    final remarks = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final c = TextEditingController();
        return AlertDialog(
          title: const Text('Reject payment'),
          content: TextField(
            controller: c,
            decoration: const InputDecoration(
              labelText: 'Remarks (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(c.text.trim()), child: const Text('Reject')),
          ],
        );
      },
    );
    if (remarks == null) return;
    await FirestoreUtils.rejectIdeaPayment(
      paymentId: p.paymentId,
      coordinatorId: widget.user.userId,
      remarks: remarks.isEmpty ? null : remarks,
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CoordinatorPaymentsData>(
      future: _load(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Unable to load: ${snapshot.error}');
        }
        final data = snapshot.data!;
        final pending = data.payments
            .where((p) => p.status != PaymentRecordStatus.verified)
            .toList(growable: false)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final verified = data.payments
            .where((p) => p.status == PaymentRecordStatus.verified)
            .toList(growable: false)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TabBar(
              controller: _tabController,
              tabs: const <Widget>[
                Tab(text: 'Pending'),
                Tab(text: 'Verified'),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  _buildList(pending, data),
                  _buildList(verified, data),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildList(List<PaymentModel> items, _CoordinatorPaymentsData data) {
    if (items.isEmpty) return const Center(child: Text('No items.'));
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final p = items[index];
        final teamName = data.teamNameById[p.teamId] ?? p.teamId;
        final student = data.studentNameById[p.paidByStudentId] ?? p.paidByStudentId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: CoordinatorPaymentCard(
            payment: p,
            problemNumber: p.problemNumber,
            teamName: teamName,
            studentName: student,
            onViewScreenshot: () => _viewShot(p),
            onApprove: () => _approve(p),
            onReject: () => _reject(p),
          ),
        );
      },
    );
  }
}

class _CoordinatorPaymentsData {
  const _CoordinatorPaymentsData({
    required this.payments,
    required this.teamNameById,
    required this.studentNameById,
  });

  final List<PaymentModel> payments;
  final Map<String, String> teamNameById;
  final Map<String, String> studentNameById;
}
