import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';

/// Shared Download Template card for CSV/Excel import first screens.
class ImportDownloadTemplateSection extends StatelessWidget {
  const ImportDownloadTemplateSection({
    super.key,
    required this.requiredColumns,
    required this.optionalColumns,
    required this.guidancePoints,
    required this.downloadLabel,
    required this.uploadLabel,
    required this.onDownload,
    required this.onUpload,
    this.enabled = true,
    this.uploadEnabled = true,
    this.uploadIcon = AppIcons.attachments,
    this.compact = false,
  });

  final List<String> requiredColumns;
  final List<String> optionalColumns;
  final List<String> guidancePoints;
  final String downloadLabel;
  final String uploadLabel;
  final VoidCallback onDownload;
  final VoidCallback onUpload;
  final bool enabled;
  final bool uploadEnabled;
  final IconData uploadIcon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(AppIcons.download, size: 16, color: Color(0xFF334155)),
              SizedBox(width: 8),
              Text(
                'Download Template',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF334155)),
              ),
            ],
          ),
          if (requiredColumns.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            _columnsLine(label: 'Required columns', columns: requiredColumns),
          ],
          if (optionalColumns.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            _columnsLine(label: 'Optional columns', columns: optionalColumns),
          ],
          if (guidancePoints.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            _guidancePoints(guidancePoints),
          ],
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: enabled ? onDownload : null,
                icon: const Icon(AppIcons.download, size: 16),
                label: Text(downloadLabel),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: enabled && uploadEnabled ? onUpload : null,
                icon: Icon(uploadIcon, size: 16),
                label: Text(uploadLabel),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 10 : 14,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _columnsLine({required String label, required List<String> columns}) {
    const TextStyle base = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.45,
      color: Color(0xFF475569),
    );
    return Text.rich(
      TextSpan(
        children: <InlineSpan>[
          TextSpan(
            text: '$label: ',
            style: base.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
          ),
          TextSpan(text: columns.join(', ')),
        ],
      ),
      style: base,
    );
  }

  static Widget _guidancePoints(List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (var i = 0; i < points.length; i++) ...<Widget>[
          if (i > 0) const SizedBox(height: 7),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Color(0xFF4F46E5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  points[i],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
