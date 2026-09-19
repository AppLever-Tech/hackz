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

class IdeaOriginalityAnalysisPanel extends StatefulWidget {
  const IdeaOriginalityAnalysisPanel({
    super.key,
    required this.ideaId,
    required this.ideaStatus,
    required this.organisationId,
    required this.user,
  });

  final String ideaId;
  final IdeaStatus ideaStatus;
  final String organisationId;
  final UserModel user;

  @override
  State<IdeaOriginalityAnalysisPanel> createState() => _IdeaOriginalityAnalysisPanelState();
}

class _IdeaOriginalityAnalysisPanelState extends State<IdeaOriginalityAnalysisPanel> {
  bool _busy = false;

  bool get _eligible => IdeaAnalysisAccess.ideaEligibleForAnalysis(widget.ideaStatus);

  String get _orgId => widget.organisationId.trim().isEmpty ? widget.user.orgId.trim() : widget.organisationId.trim();

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

  static String _panelTitle(List<AnalysisCapability> capabilities) {
    final bool similarity = capabilities.contains(AnalysisCapability.similarity);
    final bool aiWriting = capabilities.contains(AnalysisCapability.aiWriting);
    if (similarity && aiWriting) return 'Originality & AI Analysis';
    if (similarity) return 'Originality Analysis';
    if (aiWriting) return 'AI Writing Analysis';
    return 'Originality & AI Analysis';
  }

  static String _formatPercent(double? value) {
    if (value == null) return '—';
    if (value == value.roundToDouble()) return '${value.round()}%';
    return '${value.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    if (!IdeaAnalysisAccess.canManageAnalysis(widget.user)) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<AnalysisProviderPublicConfig>(
      stream: AnalysisProviderRepository.watchOrganisation(_orgId),
      builder: (BuildContext context, AsyncSnapshot<AnalysisProviderPublicConfig> configSnap) {
        final AnalysisProviderPublicConfig providerConfig =
            configSnap.data ?? AnalysisProviderPublicConfig.empty(_orgId);
        final bool providerReady = providerConfig.enabled &&
            providerConfig.credentialsConfigured &&
            providerConfig.connectionStatus == AnalysisConnectionStatus.connected;

        return StreamBuilder<IdeaAnalysisRecord?>(
          stream: IdeaAnalysisRepository.watchLatestForIdea(widget.ideaId),
          builder: (BuildContext context, AsyncSnapshot<IdeaAnalysisRecord?> analysisSnap) {
            if (analysisSnap.hasError) {
              return _shell(
                context,
                title: _panelTitle(providerConfig.capabilities),
                child: const Text(
                  'Unable to load analysis history. Check tenant Firestore access and try again.',
                  style: _mutedStyle,
                ),
              );
            }

            final IdeaAnalysisRecord? record = analysisSnap.data;
            final List<AnalysisCapability> caps = record?.capabilities.isNotEmpty == true
                ? record!.capabilities
                : providerConfig.capabilities;

            return _shell(
              context,
              title: _panelTitle(caps),
              child: _body(context, providerConfig, providerReady, record, caps),
            );
          },
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    AnalysisProviderPublicConfig providerConfig,
    bool providerReady,
    IdeaAnalysisRecord? record,
    List<AnalysisCapability> caps,
  ) {
    if (!providerReady) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Connect an analysis provider under AI Analysis Providers before running checks.',
            style: _mutedStyle,
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
        style: _mutedStyle,
      );
    }

    if (record == null) {
      return _actionsOnly(showRun: true, showRefresh: false, showRetry: false, analysisId: null);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (record.isInProgress) ...<Widget>[
          Row(
            children: <Widget>[
              const SizedBox(
                width: 18,
                height: 18,
                child: HkzProgressIndicator(size: 18, strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                record.status.label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Provider processing may take a few minutes. Use Refresh to pull the latest result.',
            style: _mutedStyle,
          ),
        ] else if (record.status == IdeaAnalysisStatus.failed) ...<Widget>[
          Text(
            record.failureMessage?.trim().isNotEmpty == true
                ? record.failureMessage!.trim()
                : 'Analysis failed.',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFB91C1C), height: 1.4),
          ),
        ] else if (record.status == IdeaAnalysisStatus.completed) ...<Widget>[
          if (caps.contains(AnalysisCapability.similarity))
            _metricRow('Similarity', _formatPercent(record.similarityPercent)),
          if (caps.contains(AnalysisCapability.aiWriting)) ...<Widget>[
            if (caps.contains(AnalysisCapability.similarity)) const SizedBox(height: 4),
            _metricRow('AI-Writing Indicator', _formatPercent(record.aiWritingPercent)),
          ],
          if (caps.contains(AnalysisCapability.matchingSources)) ...<Widget>[
            const SizedBox(height: 4),
            _metricRow(
              'Matching Sources',
              record.matchingSourceCount == null ? '—' : '${record.matchingSourceCount}',
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${record.provider.label} • ${_formatAnalysisDate(record)}',
            style: _mutedStyle,
          ),
          if (caps.contains(AnalysisCapability.fullReport) && record.fullReportAvailable) ...<Widget>[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _openReport(record.analysisId),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('View Full Report'),
            ),
          ],
        ],
        const SizedBox(height: 10),
        _actionsOnly(
          showRun: !record.isInProgress,
          showRefresh: record.isInProgress || record.status == IdeaAnalysisStatus.completed,
          showRetry: record.status == IdeaAnalysisStatus.failed,
          analysisId: record.analysisId,
        ),
      ],
    );
  }

  Widget _actionsOnly({
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

  static Widget _metricRow(String label, String value) {
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

  static String _formatAnalysisDate(IdeaAnalysisRecord record) {
    final DateTime when = record.completedAt ?? record.createdAt;
    return formatDateTime(when);
  }

  static Widget _shell(BuildContext context, {required String title, required Widget child}) {
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

  static const TextStyle _mutedStyle = TextStyle(
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: Color(0xFF64748B),
  );
}
