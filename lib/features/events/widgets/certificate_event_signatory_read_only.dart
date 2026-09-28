import 'package:flutter/material.dart';

import '../../exports/certificate/certificate_event_signatory_config.dart';
import '../../exports/certificate/certificate_event_signatory_store.dart';

/// Compact read-only signatory list for the generate dialog.
class CertificateEventSignatoryReadOnlySummary extends StatelessWidget {
  const CertificateEventSignatoryReadOnlySummary({
    super.key,
    required this.draft,
    this.compact = true,
  });

  final CertificateEventSignatoryDraft? draft;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final int count = CertificateEventSignatoryConfig.normalizedCount(draft);
    final List<CertificateSignatorySlotDraft> slots = CertificateEventSignatoryConfig.normalizedSlots(draft);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Certificate signatories',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          if (!CertificateEventSignatoryConfig.meetsMinimum(draft))
            const Text(
              'Configure at least 2 signatories on the e-Certificates tab before generating.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
            )
          else
            for (int i = 0; i < count; i++) ...<Widget>[
              if (i > 0) SizedBox(height: compact ? 4 : 8),
              _line(slots[i], compact: compact),
            ],
        ],
      ),
    );
  }

  Widget _line(CertificateSignatorySlotDraft slot, {required bool compact}) {
    final String name = slot.name.trim();
    final String designation = slot.designation.trim();
    final String text = designation.isEmpty ? name : '$name · $designation';
    return Text(
      text,
      maxLines: compact ? 1 : 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
    );
  }
}
