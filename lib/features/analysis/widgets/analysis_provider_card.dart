import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../models/analysis_provider_models.dart';

class AnalysisProviderCard extends StatelessWidget {
  const AnalysisProviderCard({
    super.key,
    required this.provider,
    required this.selected,
    required this.config,
    required this.canConfigure,
    this.disabledReason,
    this.onSelect,
    this.onConfigure,
    this.onTest,
    this.onReplaceCredentials,
  });

  final AnalysisProviderType provider;
  final bool selected;
  final AnalysisProviderPublicConfig? config;
  final bool canConfigure;
  final String? disabledReason;
  final VoidCallback? onSelect;
  final VoidCallback? onConfigure;
  final VoidCallback? onTest;
  final VoidCallback? onReplaceCredentials;

  (Color fg, Color bg) _statusColors(AnalysisConnectionStatus status, ColorScheme cs) {
    return switch (status) {
      AnalysisConnectionStatus.connected => (const Color(0xFF047857), const Color(0xFFECFDF5)),
      AnalysisConnectionStatus.error => (cs.error, cs.errorContainer.withValues(alpha: 0.35)),
      AnalysisConnectionStatus.notConfigured => (const Color(0xFF64748B), const Color(0xFFF8FAFC)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AnalysisConnectionStatus status =
        config?.connectionStatus ?? AnalysisConnectionStatus.notConfigured;
    final (Color fg, Color bg) = _statusColors(status, cs);
    final bool configured = config?.credentialsConfigured ?? false;

    return Material(
      color: cs.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? cs.primary.withValues(alpha: 0.55) : cs.outlineVariant.withValues(alpha: 0.7),
          width: selected ? 1.6 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.psychology_outlined, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    provider.label,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: fg.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    disabledReason != null ? 'Unavailable' : status.label,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: fg),
                  ),
                ),
              ],
            ),
            if (disabledReason != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                disabledReason!,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
            if (config != null && config!.capabilities.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: config!.capabilities
                    .map(
                      (AnalysisCapability cap) => Chip(
                        label: Text(cap.label),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            if (configured && config != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                'Credentials: configured (secret stored server-side — not shown in Hackz)',
                style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
              ),
              if ((config!.apiBaseUrl ?? '').isNotEmpty)
                Text(
                  'API base: ${config!.apiBaseUrl}',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
            ],
            if (config?.lastError != null && config!.lastError!.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                config!.lastError!,
                style: TextStyle(fontSize: 12.5, color: cs.error),
              ),
            ],
            if (canConfigure && disabledReason == null) ...<Widget>[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  if (onConfigure != null)
                    FilledButton.icon(
                      onPressed: onConfigure,
                      icon: const Icon(AppIcons.key, size: 18),
                      label: Text(configured ? 'Replace Credentials' : 'Configure'),
                    ),
                  if (onTest != null && configured)
                    OutlinedButton.icon(
                      onPressed: onTest,
                      icon: const Icon(AppIcons.checklist, size: 18),
                      label: const Text('Test Connection'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
