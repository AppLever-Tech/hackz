import 'package:flutter/material.dart';

import '../../../core/firebase/hackz_analysis_client.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../../features/user/models/enums/user_role.dart';
import '../../../features/user/models/user_model.dart';
import '../../../utils/common_helpers.dart';
import '../models/analysis_provider_models.dart';
import '../services/analysis_provider_repository.dart';
import '../widgets/analysis_provider_card.dart';
import '../widgets/configure_turnitin_dialog.dart';

class AiAnalysisProvidersScreen extends StatelessWidget {
  const AiAnalysisProvidersScreen({
    super.key,
    required this.user,
    this.readOnly = false,
  });

  final UserModel user;
  final bool readOnly;

  bool get _canConfigure =>
      !readOnly && UserRole.fromCode(user.role) == UserRole.collegeAdmin;

  Future<void> _configure(BuildContext context, AnalysisProviderType provider) async {
    if (!_canConfigure) return;
    if (provider == AnalysisProviderType.drillbit) {
      await FeedbackService.showInfo(
        context,
        title: 'DrillBit',
        message: 'DrillBit is not available until Hackz confirms provider API details.',
      );
      return;
    }
    final Map<String, String>? credentials = await showConfigureTurnitinDialog(context: context);
    if (credentials == null || !context.mounted) return;
    try {
      await HackzAnalysisClient.saveProviderCredentials(
        organisationId: user.orgId,
        provider: provider,
        credentials: credentials,
      );
      if (!context.mounted) return;
      await FeedbackService.showSuccess(
        context,
        title: 'Credentials saved',
        message: 'Turnitin credentials were stored securely. Connection status updated.',
      );
    } on HackzAnalysisException catch (e) {
      if (!context.mounted) return;
      await FeedbackService.showError(context, title: 'Unable to save', message: e.message);
    } catch (e) {
      if (!context.mounted) return;
      await FeedbackService.showError(context, title: 'Unable to save', message: '$e');
    }
  }

  Future<void> _testConnection(
    BuildContext context,
    AnalysisProviderPublicConfig config,
  ) async {
    if (!_canConfigure) return;
    try {
      final result = await HackzAnalysisClient.testConnection(
        organisationId: user.orgId,
        provider: config.provider,
      );
      if (!context.mounted) return;
      if (result.ok) {
        await FeedbackService.showSuccess(
          context,
          title: 'Connection verified',
          message: result.message,
        );
      } else {
        await FeedbackService.showError(context, title: 'Connection failed', message: result.message);
      }
    } on HackzAnalysisException catch (e) {
      if (!context.mounted) return;
      await FeedbackService.showError(context, title: 'Test failed', message: e.message);
    }
  }

  Future<void> _replaceCredentials(BuildContext context, AnalysisProviderType provider) async {
    await _configure(context, provider);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AnalysisProviderPublicConfig>(
      stream: AnalysisProviderRepository.watchOrganisation(user.orgId),
      builder: (BuildContext context, AsyncSnapshot<AnalysisProviderPublicConfig> snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: HkzProgressIndicator());
        }
        final AnalysisProviderPublicConfig config =
            snap.data ?? AnalysisProviderPublicConfig.empty(user.orgId);
        final AnalysisProviderType activeProvider = config.credentialsConfigured
            ? config.provider
            : AnalysisProviderType.turnitin;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.psychology_outlined, color: Theme.of(context).colorScheme.primary, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'AI Analysis Providers',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          readOnly
                              ? 'Provider status and licensed capabilities (support view — credentials are never shown).'
                              : 'Configure originality and AI-writing analysis for your organisation.',
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.45,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (readOnly)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Hackz orgAdmin can view status only. College Admin owns credential configuration.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              AnalysisProviderCard(
                provider: AnalysisProviderType.turnitin,
                selected: activeProvider == AnalysisProviderType.turnitin,
                config: config.provider == AnalysisProviderType.turnitin ? config : null,
                canConfigure: _canConfigure,
                onSelect: _canConfigure
                    ? () => _configure(context, AnalysisProviderType.turnitin)
                    : null,
                onConfigure: _canConfigure
                    ? () => _configure(context, AnalysisProviderType.turnitin)
                    : null,
                onTest: _canConfigure && config.provider == AnalysisProviderType.turnitin
                    ? () => _testConnection(context, config)
                    : null,
                onReplaceCredentials: _canConfigure &&
                        config.provider == AnalysisProviderType.turnitin &&
                        config.credentialsConfigured
                    ? () => _replaceCredentials(context, AnalysisProviderType.turnitin)
                    : null,
              ),
              const SizedBox(height: 12),
              AnalysisProviderCard(
                provider: AnalysisProviderType.drillbit,
                selected: false,
                config: config.provider == AnalysisProviderType.drillbit ? config : null,
                canConfigure: false,
                disabledReason: 'Pending provider API documentation',
                onSelect: null,
                onConfigure: null,
                onTest: null,
                onReplaceCredentials: null,
              ),
              if (config.lastVerifiedAt != null) ...<Widget>[
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    Icon(AppIcons.clock, size: 16, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(width: 8),
                    Text(
                      'Last verified ${formatDateTime(config.lastVerifiedAt!.toLocal())}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
