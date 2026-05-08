import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../constants/app_icons.dart';
import '../../constants/status_styles.dart';
import '../../models/attachment_model.dart';
import '../../models/enums/team_status.dart';
import '../../models/enums/user_role.dart';
import '../../models/idea_model.dart';
import '../../models/payment_model.dart';
import '../../models/score_model.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../utils/firestore_utils.dart';
import '../../utils/idea_detail_config.dart';
import '../../utils/idea_details_service.dart';
import '../../widgets/attachment_viewer.dart';
import '../../widgets/payment_dialog.dart';
import 'dashboard_components.dart';
import '../../widgets/filter_pill.dart';

enum _IdeaDetailTab { details, team, payment, evaluation, attachments, activity }

class IdeaDetailScreen extends StatefulWidget {
  const IdeaDetailScreen({
    super.key,
    required this.ideaId,
    required this.currentUser,
    this.embedded = false,
    this.onBack,
  });

  final String ideaId;
  final UserModel currentUser;
  final bool embedded;
  final VoidCallback? onBack;

  @override
  State<IdeaDetailScreen> createState() => _IdeaDetailScreenState();
}

class _IdeaDetailScreenState extends State<IdeaDetailScreen> {
  final IdeaDetailsService _service = IdeaDetailsService();
  late final IdeaDetailConfig _config;
  late Future<IdeaDetailsVm> _future;
  _IdeaDetailTab _tab = _IdeaDetailTab.details;

  @override
  void initState() {
    super.initState();
    _config = IdeaDetailRoleConfig.configFor(widget.currentUser);
    _future = _service.load(ideaId: widget.ideaId, orgId: widget.currentUser.orgId);
  }

  Future<void> _reload() async {
    setState(() {
      _future = _service.load(ideaId: widget.ideaId, orgId: widget.currentUser.orgId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = FutureBuilder<IdeaDetailsVm>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) return Center(child: Text('Unable to load idea details: ${snapshot.error}'));
          final vm = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _header(vm),
                const SizedBox(height: 10),
                _summary(vm),
                const SizedBox(height: 10),
                _tabs(),
                const SizedBox(height: 10),
                Expanded(child: _tabContent(vm)),
              ],
            ),
          );
        },
      );
    if (widget.embedded) return content;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        title: const Text('Idea Details'),
      ),
      body: content,
    );
  }

  Widget _header(IdeaDetailsVm vm) {
    final payment = vm.payment;
    return SectionContainer(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  vm.idea.problemTitle.isEmpty ? vm.idea.problemNumber : vm.idea.problemTitle,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Team: ${vm.team.teamName.isEmpty ? vm.idea.teamId : vm.team.teamName}',
                  style: const TextStyle(color: Color(0xFF5B628A)),
                ),
              ],
            ),
          ),
          _ideaStatusPill(vm.idea.status),
          const SizedBox(width: 8),
          _paymentPill(payment?.status),
        ],
      ),
    );
  }

  Widget _summary(IdeaDetailsVm vm) {
    return LayoutBuilder(
      builder: (_, c) {
        const gap = 10.0;
        final cols = (c.maxWidth / 210).floor().clamp(1, 4);
        final w = (c.maxWidth - (gap * (cols - 1))) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            SizedBox(
              width: w,
              child: DashboardCountCard(
                value: vm.averageScore?.toStringAsFixed(1) ?? '-',
                label: 'Score',
                icon: AppIcons.scoring,
                iconBgColor: const Color(0xFFE8FAF1),
              ),
            ),
            SizedBox(
              width: w,
              child: DashboardCountCard(
                value: vm.scores.length.toString(),
                label: 'Evaluations',
                icon: AppIcons.statusEvaluated,
                iconBgColor: const Color(0xFFF2EDFF),
              ),
            ),
            SizedBox(
              width: w,
              child: DashboardCountCard(
                value: vm.ideaAttachments.length.toString(),
                label: 'Idea Attachments',
                icon: AppIcons.attachments,
                iconBgColor: const Color(0xFFEAF2FF),
              ),
            ),
            SizedBox(
              width: w,
              child: DashboardCountCard(
                value: vm.paymentAttachments.length.toString(),
                label: 'Payment Attachments',
                icon: AppIcons.payments,
                iconBgColor: const Color(0xFFFFF4E8),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _tabs() {
    final items = <(_IdeaDetailTab, String, IconData)>[
      (_IdeaDetailTab.details, 'Details', AppIcons.ideas),
      (_IdeaDetailTab.team, 'Team', AppIcons.teams),
      (_IdeaDetailTab.payment, 'Payment', AppIcons.payments),
      (_IdeaDetailTab.evaluation, 'Evaluation', AppIcons.scoring),
      (_IdeaDetailTab.attachments, 'Attachments', AppIcons.attachments),
      (_IdeaDetailTab.activity, 'Activity', AppIcons.insights),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterPill(
                  selected: _tab == item.$1,
                  icon: item.$3,
                  label: item.$2,
                  count: 0,
                  onTap: () => setState(() => _tab = item.$1),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  Widget _tabContent(IdeaDetailsVm vm) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: switch (_tab) {
        _IdeaDetailTab.details => _detailsTab(vm),
        _IdeaDetailTab.team => _teamTab(vm),
        _IdeaDetailTab.payment => _paymentTab(vm),
        _IdeaDetailTab.evaluation => _evaluationTab(vm),
        _IdeaDetailTab.attachments => _attachmentsTab(vm),
        _IdeaDetailTab.activity => _activityTab(vm),
      },
    );
  }

  Widget _detailsTab(IdeaDetailsVm vm) {
    return ListView(
      key: const ValueKey<String>('details'),
      children: <Widget>[
        SectionContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Idea Description', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(vm.idea.description.isEmpty ? '-' : vm.idea.description),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SectionContainer(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _pill('Problem', '${vm.idea.problemNumber} - ${vm.idea.problemTitle}'),
              _pill('Department', vm.problem.departmentDisplayName),
              _pill('Category', vm.problem.category.isEmpty ? '-' : vm.problem.category),
              _pill('Theme', vm.problem.theme.isEmpty ? '-' : vm.problem.theme),
              _pill('Submitted By', vm.idea.createdBy),
              _pill('Created', _fmt(vm.idea.createdAt)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _teamTab(IdeaDetailsVm vm) {
    return ListView(
      key: const ValueKey<String>('team'),
      children: <Widget>[
        SectionContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Team: ${vm.team.teamName.isEmpty ? vm.idea.teamId : vm.team.teamName}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Mentor: ${_name(vm.mentor)}'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: vm.students
                    .map((s) => _pill('Student', _name(s)))
                    .toList(growable: false),
              ),
              const SizedBox(height: 8),
              _pill('Team Status', vm.team.status.value),
              if (vm.team.status == TeamStatus.locked)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Team locked after submission', style: TextStyle(color: Color(0xFFB56A11))),
                ),
              if (_config.canEditTeam && vm.team.status != TeamStatus.locked)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Faculty can manage team for eligible status.'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paymentTab(IdeaDetailsVm vm) {
    final payment = vm.payment;
    return ListView(
      key: const ValueKey<String>('payment'),
      children: <Widget>[
        SectionContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (payment == null)
                const Text('No payment uploaded yet.')
              else ...<Widget>[
                _pill('Amount', payment.amount.toStringAsFixed(2)),
                const SizedBox(height: 8),
                _pill('Status', _paymentLabel(payment.status)),
                const SizedBox(height: 8),
                _pill('Submitted', _fmt(payment.createdAt)),
                if (payment.verifiedAt != null) ...<Widget>[
                  const SizedBox(height: 8),
                  _pill('Verified/Rejected', _fmt(payment.verifiedAt!)),
                ],
                if (payment.remarks.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text('Remarks: ${payment.remarks}'),
                ],
              ],
              const SizedBox(height: 10),
              AttachmentPreviewRow(
                entityType: AttachmentEntityType.payment,
                entityId: payment?.paymentId ?? vm.idea.ideaId,
                title: 'Payment Attachments',
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  if (_config.canVerifyPayment && payment != null && payment.status == PaymentRecordStatus.pending)
                    FilledButton(
                      onPressed: () async {
                        await FirestoreUtils.verifyIdeaPayment(
                          paymentId: payment.paymentId,
                          coordinatorId: widget.currentUser.userId,
                        );
                        await _reload();
                      },
                      child: const Text('Approve'),
                    ),
                  if (_config.canVerifyPayment && payment != null && payment.status == PaymentRecordStatus.pending)
                    OutlinedButton(
                      onPressed: () async {
                        final c = TextEditingController();
                        final remarks = await showDialog<String>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Reject payment'),
                            content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Remarks')),
                            actions: <Widget>[
                              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                              FilledButton(onPressed: () => Navigator.of(ctx).pop(c.text.trim()), child: const Text('Reject')),
                            ],
                          ),
                        );
                        if (remarks == null) return;
                        await FirestoreUtils.rejectIdeaPayment(
                          paymentId: payment.paymentId,
                          coordinatorId: widget.currentUser.userId,
                          remarks: remarks.isEmpty ? null : remarks,
                        );
                        await _reload();
                      },
                      child: const Text('Reject'),
                    ),
                  if (_config.canUploadPayment && vm.team.teamId.isNotEmpty)
                    FilledButton.icon(
                      onPressed: () async {
                        final ok = await showPaymentDialog(
                          context: context,
                          currentUser: widget.currentUser,
                          idea: vm.idea,
                          team: vm.team,
                        );
                        if (ok == true) await _reload();
                      },
                      icon: const Icon(AppIcons.payments, size: 16),
                      label: Text(payment == null ? 'Upload Payment' : 'Re-upload Payment'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _evaluationTab(IdeaDetailsVm vm) {
    return ListView(
      key: const ValueKey<String>('eval'),
      children: <Widget>[
        SectionContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _pill('Evaluation Status', vm.scores.isEmpty ? 'Pending' : 'Completed'),
              const SizedBox(height: 8),
              _pill('Aggregated Score', vm.averageScore?.toStringAsFixed(1) ?? '-'),
              const SizedBox(height: 10),
              if (vm.scores.isEmpty)
                const Text('No evaluations yet.')
              else
                ...vm.scores.map(
                  (s) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFF), borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Judge: ${s.judgeId} • Score: ${s.score.toStringAsFixed(1)}'),
                        if (s.feedback.trim().isNotEmpty) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(s.feedback),
                        ],
                      ],
                    ),
                  ),
                ),
              if (_config.canEvaluate) ...<Widget>[
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () => _openJudgeEvaluation(vm),
                  child: const Text('Evaluate / Update Score'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _attachmentsTab(IdeaDetailsVm vm) {
    return ListView(
      key: const ValueKey<String>('attach'),
      children: <Widget>[
        SectionContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AttachmentPreviewRow(
                entityType: AttachmentEntityType.idea,
                entityId: vm.idea.ideaId,
                title: 'Idea Attachments',
              ),
              const SizedBox(height: 10),
              if (vm.payment != null)
                AttachmentPreviewRow(
                  entityType: AttachmentEntityType.payment,
                  entityId: vm.payment!.paymentId,
                  title: 'Payment Attachments',
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _activityTab(IdeaDetailsVm vm) {
    return ListView(
      key: const ValueKey<String>('activity'),
      children: <Widget>[
        SectionContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: vm.activities
                .map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: <Widget>[
                        const Icon(AppIcons.insights, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(a.text)),
                        Text(_fmt(a.at), style: const TextStyle(fontSize: 12, color: Color(0xFF6E7394))),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }

  Future<void> _openJudgeEvaluation(IdeaDetailsVm vm) async {
    final scoreController = TextEditingController();
    final feedbackController = TextEditingController();
    final existing = vm.scores.firstWhere(
      (s) => s.judgeId == widget.currentUser.userId,
      orElse: () => ScoreModel(
        scoreId: '',
        ideaId: vm.idea.ideaId,
        judgeId: widget.currentUser.userId,
        score: 0,
        feedback: '',
        createdAt: DateTime.now(),
        orgId: widget.currentUser.orgId,
        departmentCode: vm.idea.departmentCode,
      ),
    );
    if (existing.score > 0) scoreController.text = existing.score.toStringAsFixed(1);
    feedbackController.text = existing.feedback;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Evaluate Idea'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(controller: scoreController, decoration: const InputDecoration(labelText: 'Score (1-10)')),
              const SizedBox(height: 8),
              TextField(controller: feedbackController, maxLines: 3, decoration: const InputDecoration(labelText: 'Feedback')),
            ],
          ),
        ),
        actions: <Widget>[
          OutlinedButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    final parsed = double.tryParse(scoreController.text.trim());
    if (parsed == null || parsed < 1 || parsed > 10) return;
    final col = FirebaseFirestore.instance.collection(FirestoreUtils.hkzScores);
    final current = await col
        .where('ideaId', isEqualTo: vm.idea.ideaId)
        .where('judgeId', isEqualTo: widget.currentUser.userId)
        .limit(1)
        .get();
    final model = ScoreModel(
      scoreId: current.docs.isEmpty ? '' : current.docs.first.id,
      ideaId: vm.idea.ideaId,
      judgeId: widget.currentUser.userId,
      score: parsed,
      feedback: feedbackController.text.trim(),
      createdAt: DateTime.now(),
      orgId: widget.currentUser.orgId,
      departmentCode: vm.idea.departmentCode,
    );
    if (current.docs.isEmpty) {
      final doc = col.doc();
      await doc.set(_scoreWithId(model, doc.id).toMap());
    } else {
      await col.doc(current.docs.first.id).update(model.toMap());
    }
    await FirebaseFirestore.instance
        .collection(FirestoreUtils.hkzIdeas)
        .doc(vm.idea.ideaId)
        .update(<String, dynamic>{'status': IdeaStatus.evaluated.value});
    await _reload();
  }

  ScoreModel _scoreWithId(ScoreModel score, String id) {
    return ScoreModel(
      scoreId: id,
      ideaId: score.ideaId,
      judgeId: score.judgeId,
      score: score.score,
      feedback: score.feedback,
      createdAt: score.createdAt,
      orgId: score.orgId,
      departmentCode: score.departmentCode,
    );
  }

  Widget _pill(String k, String v) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
        child: Text('$k: $v'),
      );

  Widget _ideaStatusPill(IdeaStatus status) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: StatusStyles.colorForIdeaStatus(status).withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(StatusStyles.iconForIdeaStatus(status), size: 14, color: StatusStyles.colorForIdeaStatus(status)),
            const SizedBox(width: 6),
            Text(_ideaLabel(status), style: TextStyle(color: StatusStyles.colorForIdeaStatus(status))),
          ],
        ),
      );

  Widget _paymentPill(PaymentRecordStatus? status) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: const Color(0xFFF4F5FA), borderRadius: BorderRadius.circular(20)),
        child: Text('Payment: ${_paymentLabel(status)}'),
      );

  String _ideaLabel(IdeaStatus status) {
    switch (status) {
      case IdeaStatus.pendingSubmission:
        return 'Pending';
      case IdeaStatus.submitted:
        return 'Submitted';
      case IdeaStatus.underReview:
        return 'Under Review';
      case IdeaStatus.evaluated:
        return 'Evaluated';
      case IdeaStatus.approved:
        return 'Approved';
      case IdeaStatus.rejected:
        return 'Rejected';
    }
  }

  String _paymentLabel(PaymentRecordStatus? status) {
    if (status == null) return '-';
    switch (status) {
      case PaymentRecordStatus.pending:
        return 'Pending';
      case PaymentRecordStatus.verified:
        return 'Verified';
      case PaymentRecordStatus.rejected:
        return 'Rejected';
    }
  }

  String _fmt(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _name(UserModel? u) {
    if (u == null) return '-';
    final n = '${u.firstName} ${u.lastName}'.trim();
    return n.isEmpty ? u.userId : n;
  }
}
