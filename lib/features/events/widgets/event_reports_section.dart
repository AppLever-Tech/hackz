import 'package:flutter/material.dart';

import '../../../core/responsive/mobile_toolbar_button_styles.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_icons.dart';
import '../../exports/exports.dart';
import '../models/event_report_item.dart';
import 'event_detail_section.dart';
import 'event_meta_chip.dart';

/// Event Reports module reused by Ideathon and future Hackathon.
class EventReportsSection extends StatelessWidget {
  const EventReportsSection({
    super.key,
    required this.items,
    this.certificatesReady = true,
    this.onOpenSignatories,
  });

  final List<EventReportItem> items;
  final bool certificatesReady;
  final VoidCallback? onOpenSignatories;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < items.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 10),
          _ReportCard(
            item: items[i],
            certificatesReady: certificatesReady,
            onOpenSignatories: onOpenSignatories,
          ),
        ],
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.item,
    required this.certificatesReady,
    this.onOpenSignatories,
  });

  final EventReportItem item;
  final bool certificatesReady;
  final VoidCallback? onOpenSignatories;

  @override
  Widget build(BuildContext context) {
    return EventDetailSection(
      title: item.title,
      icon: item.icon,
      titleFontSize: 14,
      titleFontWeight: FontWeight.w900,
      titleColor: const Color(0xFF0F172A),
      trailing: _action(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            item.description,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Color(0xFF475569),
            ),
          ),
          if (item.metaPills.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.metaPills
                  .map(
                    (EventReportMetaPill pill) => EventMetaChip(
                      label: pill.label,
                      icon: pill.icon ?? AppIcons.info,
                      color: pill.color,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (!item.available &&
              item.unavailableReason.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              item.unavailableReason,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
          if (item.available && !certificatesReady) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: <Widget>[
                const Text(
                  'Add at least 2 signatories to generate certificates.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                if (onOpenSignatories != null)
                  TextButton(onPressed: onOpenSignatories, child: const Text('Signatories')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _action(BuildContext context) {
    final ExportDataProvider? provider = item.provider;
    final ExportRequest Function(ExportFormat format)? requestFor = item.requestFor;
    final bool compact = ResponsiveHelper.isMobile(context);
    final bool actionsEnabled = item.available && certificatesReady;
    final void Function(BuildContext context)? onGenerate = actionsEnabled ? item.onGenerate : null;

    final ExportDataProvider? exportProvider = provider;
    final ExportRequest Function(ExportFormat format)? exportRequestFor = requestFor;
    final bool hasDownload = exportProvider != null && exportRequestFor != null;

    final Widget? download = !hasDownload
        ? null
        : actionsEnabled
            ? ExportDownloadButton(
                labeled: !compact,
                label: item.actionLabel,
                provider: exportProvider,
                requestFor: exportRequestFor,
              )
            : OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(AppIcons.download, size: MobileToolbarButtonStyles.toolbarIconSize),
                label: Text(item.actionLabel),
                style: MobileToolbarButtonStyles.outlined(compact: true),
              );

    if (onGenerate == null) {
      if (download == null) return const SizedBox.shrink();
      return FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: download);
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          OutlinedButton(
            onPressed: () => onGenerate(context),
            style: MobileToolbarButtonStyles.outlined(compact: true),
            child: Text(item.generateLabel),
          ),
          if (download != null) download,
        ],
      ),
    );
  }
}
