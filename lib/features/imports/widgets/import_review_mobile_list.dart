import 'package:flutter/material.dart';

import '../models/import_review_row.dart';
import '../models/import_row_severity.dart';

class ImportReviewMobileList extends StatelessWidget {
  const ImportReviewMobileList({super.key, required this.rows});

  final List<ImportReviewRow> rows;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final ImportReviewRow row = rows[index];
        final Color color = switch (row.severity) {
          ImportRowSeverity.valid => const Color(0xFF047857),
          ImportRowSeverity.warning => const Color(0xFFB45309),
          ImportRowSeverity.error => const Color(0xFFB91C1C),
        };
        final String role = row.valueFor('role');
        final String department = row.valueFor('department');
        final String deptStatus = row.metadata['departmentStatus'] ?? '';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFDFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                row.valueFor('name').isEmpty ? 'Row ${row.rowNumber}' : row.valueFor('name'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              if (role.isNotEmpty || department.isNotEmpty) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  <String>[role, department].where((String s) => s.isNotEmpty).join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                row.statusLabel,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
              ),
              if (deptStatus.isNotEmpty)
                Text(
                  deptStatus,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
            ],
          ),
        );
      },
    );
  }
}
