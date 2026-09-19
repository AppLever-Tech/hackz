import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/firebase/hackz_analysis_client.dart';
import '../../../core/ui/feedback/services/feedback_service.dart';
import '../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../../features/dashboard/chrome/dashboard_components.dart';
import '../../../utils/common_helpers.dart';
import '../../idea/models/enums/idea_status.dart';
import '../../user/models/user_model.dart';
import '../models/analysis_provider_models.dart';
import '../models/idea_analysis_record.dart';
import '../services/analysis_provider_repository.dart';
import '../services/idea_analysis_access.dart';
import '../services/idea_analysis_repository.dart';

enum IdeaOriginalityAnalysisPresentation { admin, judge }

/// Shared originality analysis card for Idea Details (admin) and Judge Evaluation (read-only).
class IdeaOriginalityAnalysisView extends StatefulWidget {
  const IdeaOriginalityAnalysisView({
    super.key,
    required this.ideaId,
    required this.organisationId,
    required this.presentation,
    this.ideaStatus,
    this.user,
  });

  final String ideaId;
  final String organisationId;
  final IdeaOriginalityAnalysisPresentation presentation;
  final IdeaStatus? ideaStatus;
  final UserModel? user;

  bool get _isAdmin => presentation == IdeaOriginalityAnalysisPresentation.admin;

  @override
  State<IdeaOriginalityAnalysisView> createState() => _IdeaOriginalityAnalysisViewState();
}

class _IdeaOriginalityAnalysisViewState extends State<IdeaOriginalityAnalysisView> {
  bool _busy = false;

  String get _orgId {
    final String fromWidget = widget.organisationId.trim();
    if (fromWidget.isNotEmpty) return fromWidget;
    return widget.user?.orgId.trim() ?? '';
  }

  bool get _eligible =>
      widget.ideaStatus == null || IdeaAnalysisAccess.ideaEligibleForAnalysis(widget.ideaStatus!);

  Future<void> _runAnalysis() async {
    setState(() => _busy = true);
    try {
      await HackzAnalysisClient.runIdeaAnalysis(
        organisationId: _orgId,
        ideaId: widget.ideaId,
      );
      if (!mounted) return;
      await FeedbackService.showSuccess(
        context,
        title: 'Analysis started',
        message: 'Results will appear here when processing completes.',
      );
    } on HackzAnalysisException catch (e) {
      if (!mounted) return;
      await FeedbackService.showError(context, title: 'Unable to run analysis', message: e.message);
    } catch (e) {
      if (!mounted) return;
      await FeedbackService.showError(context, title: 'Unable to run analysis', message: '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refresh(String analysisId) async {
    setState(() => _busy = true);
    try {
      await HackzAnalysisClient.refreshIdeaAnalysis(
        organisationId: _orgId,
        analysisId: analysisId,
      );
    } on HackzAnalysisException catch (e) {
      if (!mounted) return;
      await FeedbackService.showError(context, title: 'Refresh failed', message: e.message);
    } catch (e) {
      if (!mounted) return;
      await FeedbackService.showError(context, title: 'Refresh failed', message: '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openReport(String analysisId) async {
    setState(() => _busy = true);
    try {
      final String url = await HackzAnalysisClient.getIdeaAnalysisReportUrl(
        organisationId: _orgId,
        analysisId: analysisId,
      );
      final Uri? uri = Uri.tryParse(url);
      if (uri == null) {
        throw const HackzAnalysisException('NOT_AVAILABLE', 'Invalid report URL.');
      }
      final bool opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        await FeedbackService.showError(
          context,
          title: 'Unable to open report',
          message: 'Could not launch the provider report viewer.',
        );
      }
    } on HackzAnalysisException catch (e) {
      if (!mounted) return;
      await FeedbackService.showError(context, title: 'Full report unavailable', message: e.message);
    } catch (e) {
      if (!mounted) return;
      await FeedbackService.showError(context, title: 'Full report unavailable', message: '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget._isAdmin) {
      final UserModel? user = widget.user;
      if (user == null || !IdeaAnalysisAccess.canManageAnalysis(user)) {
        return const SizedBox.shrink();
      }
    }

    return StreamBuilder<AnalysisProviderPublicConfig>(
      stream: AnalysisProviderRepository.watchOrganisation(_orgId),
      builder: (BuildContext context, AsyncSnapshot<AnalysisProviderPublicConfig> configSnap) {
        final AnalysisProviderPublicConfig providerConfig =
            configSnap.data ?? AnalysisProviderPublicConfig.empty(_orgId);
        final bool providerReady = providerConfig.enabled &&
            providerConfig.credentialsConfigured &&
            providerConfig.connectionStatus == AnalysisConnectionStatus.connected;

        return StreamBuilder<IdeaAnalysisSnapshot>(
          stream: IdeaAnalysisRepository.watchSnapshotForIdea(widget.ideaId),
          builder: (BuildContext context, AsyncSnapshot<IdeaAnalysisSnapshot> analysisSnap) {
            if (analysisSnap.hasError) {
              return _shell(
                title: panelTitle(providerConfig.capabilities),
                child: Text(
                  widget._isAdmin
                      ? 'Unable to load analysis history. Check tenant Firestore access and try again.'
                      : 'Originality analysis not available.',
                  style: originalityAnalysisMutedStyle,
                ),
              );
            }

            final IdeaAnalysisSnapshot snapshot = analysisSnap.data ?? const IdeaAnalysisSnapshot();
            final IdeaAnalysisRecord? record = snapshot.latest;
            final List<AnalysisCapability> caps = record?.capabilities.isNotEmpty == true
                ? record!.capabilities
                : providerConfig.capabilities;

            return _shell(
              title: panelTitle(caps),
              child: _body(providerConfig, providerReady, snapshot, caps),
            );
          },
        );
      },
    );
  }

  Widget _body(
    AnalysisProviderPublicConfig providerConfig,
    bool providerReady,
    IdeaAnalysisSnapshot snapshot,
    List<AnalysisCapability> caps,
  ) {
    final IdeaAnalysisRecord? record = snapshot.latest;
    final IdeaAnalysisRecord? completed = snapshot.latestCompleted;

    if (widget._isAdmin) {
      if (!providerReady) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Connect an analysis provider under AI Analysis Providers before running checks.',
              style: originalityAnalysisMutedStyle,
            ),
            if (providerConfig.lastError != null && providerConfig.lastError!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                providerConfig.lastError!,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFB91C1C)),
              ),
            ],
          ],
        );
      }
      if (!_eligible) {
        return const Text(
          'Originality analysis is available after the idea is submitted.',
          style: originalityAnalysisMutedStyle,
        );
      }
      if (record == null) {
        return _adminActions(showRun: true, showRefresh: false, showRetry: false, analysisId: null);
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ..._statusAndMetrics(record: record, caps: caps),
          const SizedBox(height: 10),
          _adminActions(
            showRun: !record.isInProgress,
            showRefresh: record.isInProgress || record.status == IdeaAnalysisStatus.completed,
            showRetry: record.status == IdeaAnalysisStatus.failed,
            analysisId: record.analysisId,
          ),
        ],
      );
    }

    if (!providerReady || (record == null && completed == null)) {
      return const Text(
        'Originality analysis not available.',
        style: originalityAnalysisMutedStyle,
      );
    }

    if (completed == null && record != null && record.isInProgress) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Reference only — does not affect your score or submission outcome.',
              style: originalityAnalysisMutedStyle,
            ),
          ),
          _inProgressRow(record.status),
        ],
      );
    }

    if (completed == null) {
      return const Text(
        'Originality analysis not available.',
        style: originalityAnalysisMutedStyle,
      );
    }

    final bool newerInProgress =
        record != null && record.isInProgress && record.analysisId != completed.analysisId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Reference only — does not affect your score or submission outcome.',
            style: originalityAnalysisMutedStyle,
          ),
        ),
        if (newerInProgress) ...<Widget>[
          _inProgressRow(record.status),
          const SizedBox(height: 8),
        ],
        ...buildCompletedMetrics(completed, caps),
        const SizedBox(height: 8),
        Text(
          '${completed.provider.label} • ${formatAnalysisDate(completed)}',
          style: originalityAnalysisMutedStyle,
        ),
        if (caps.contains(AnalysisCapability.fullReport) && completed.fullReportAvailable) ...<Widget>[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _openReport(completed.analysisId),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('View Full Report'),
          ),
        ],
      ],
    );
  }

  List<Widget> _statusAndMetrics({
    required IdeaAnalysisRecord record,
    required List<AnalysisCapability> caps,
  }) {
    if (record.isInProgress) {
      return <Widget>[
        _inProgressRow(record.status),
        const SizedBox(height: 8),
        const Text(
          'Provider processing may take a few minutes. Use Refresh to pull the latest result.',
          style: originalityAnalysisMutedStyle,
        ),
      ];
    }
    if (record.status == IdeaAnalysisStatus.failed) {
      return <Widget>[
        Text(
          record.failureMessage?.trim().isNotEmpty == true
              ? record.failureMessage!.trim()
              : 'Analysis failed.',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFB91C1C), height: 1.4),
        ),
      ];
    }
    if (record.status == IdeaAnalysisStatus.completed) {
      return <Widget>[
        ...buildCompletedMetrics(record, caps),
        const SizedBox(height: 8),
        Text(
          '${record.provider.label} • ${formatAnalysisDate(record)}',
          style: originalityAnalysisMutedStyle,
        ),
        if (caps.contains(AnalysisCapability.fullReport) && record.fullReportAvailable) ...<Widget>[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _openReport(record.analysisId),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('View Full Report'),
          ),
        ],
      ];
    }
    return const <Widget>[];
  }

  Widget _inProgressRow(IdeaAnalysisStatus status) {
    return Row(
      children: <Widget>[
        const SizedBox(
          width: 18,
          height: 18,
          child: HkzProgressIndicator(size: 18, strokeWidth: 2),
        ),
        const SizedBox(width: 8),
        Text(
          status.label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }

  Widget _adminActions({
    required bool showRun,
    required bool showRefresh,
    required bool showRetry,
    required String? analysisId,
  }) {
    final List<Widget> buttons = <Widget>[];
    if (showRun) {
      buttons.add(
        FilledButton(
          onPressed: _busy ? null : _runAnalysis,
          child: const Text('Run Analysis'),
        ),
      );
    }
    if (showRetry) {
      buttons.add(
        FilledButton(
          onPressed: _busy ? null : _runAnalysis,
          child: const Text('Retry'),
        ),
      );
    }
    if (showRefresh && analysisId != null) {
      buttons.add(
        OutlinedButton(
          onPressed: _busy ? null : () => _refresh(analysisId),
          child: const Text('Refresh'),
        ),
      );
    }
    if (buttons.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: buttons,
    );
  }

  Widget _shell({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: kDashboardCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.psychology_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

String panelTitle(List<AnalysisCapability> capabilities) {
  final bool similarity = capabilities.contains(AnalysisCapability.similarity);
  final bool aiWriting = capabilities.contains(AnalysisCapability.aiWriting);
  if (similarity && aiWriting) return 'Originality & AI Analysis';
  if (similarity) return 'Originality Analysis';
  if (aiWriting) return 'AI Writing Analysis';
  return 'Originality & AI Analysis';
}

String formatAnalysisPercent(double? value) {
  if (value == null) return '—';
  if (value == value.roundToDouble()) return '${value.round()}%';
  return '${value.toStringAsFixed(1)}%';
}

String formatAnalysisDate(IdeaAnalysisRecord record) {
  final DateTime when = record.completedAt ?? record.createdAt;
  return formatDateTime(when);
}

List<Widget> buildCompletedMetrics(IdeaAnalysisRecord record, List<AnalysisCapability> caps) {
  return <Widget>[
    if (caps.contains(AnalysisCapability.similarity))
      originalityAnalysisMetricRow('Similarity', formatAnalysisPercent(record.similarityPercent)),
    if (caps.contains(AnalysisCapability.aiWriting)) ...<Widget>[
      if (caps.contains(AnalysisCapability.similarity)) const SizedBox(height: 4),
      originalityAnalysisMetricRow('AI-Writing Indicator', formatAnalysisPercent(record.aiWritingPercent)),
    ],
    if (caps.contains(AnalysisCapability.matchingSources)) ...<Widget>[
      const SizedBox(height: 4),
      originalityAnalysisMetricRow(
        'Matching Sources',
        record.matchingSourceCount == null ? '—' : '${record.matchingSourceCount}',
      ),
    ],
  ];
}

Widget originalityAnalysisMetricRow(String label, String value) {
  return Row(
    children: <Widget>[
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
      ),
      Text(
        value,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
      ),
    ],
  );
}

const TextStyle originalityAnalysisMutedStyle = TextStyle(
  fontSize: 12,
  height: 1.4,
  fontWeight: FontWeight.w500,
  color: Color(0xFF64748B),
);
