import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../exports/certificate/certificate_event_signatory_config.dart';
import '../../exports/certificate/certificate_event_signatory_store.dart';
import 'event_detail_section.dart';

/// Collapsible signatory summary on the e-Certificates screen.
class CertificateEventSignatoryPanel extends StatefulWidget {
  const CertificateEventSignatoryPanel({
    super.key,
    required this.draft,
    required this.onEdit,
  });

  final CertificateEventSignatoryDraft? draft;
  final VoidCallback onEdit;

  @override
  State<CertificateEventSignatoryPanel> createState() => _CertificateEventSignatoryPanelState();
}

class _CertificateEventSignatoryPanelState extends State<CertificateEventSignatoryPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final bool ready = CertificateEventSignatoryConfig.meetsMinimum(widget.draft);
    final int count = CertificateEventSignatoryConfig.validCount(
      widget.draft ?? const CertificateEventSignatoryDraft(),
    );
    final int configured = CertificateEventSignatoryConfig.normalizedCount(widget.draft);
    final List<CertificateSignatorySlotDraft> slots =
        CertificateEventSignatoryConfig.normalizedSlots(widget.draft);

    final String subtitle = ready
        ? '$configured signator${configured == 1 ? 'y' : 'ies'} configured'
        : '$count of ${CertificateEventSignatoryConfig.minimumSignatories} required';

    return EventDetailSection(
      title: 'Certificate signatories',
      icon: AppIcons.achievement,
      titleFontSize: 14,
      titleFontWeight: FontWeight.w900,
      titleColor: const Color(0xFF0F172A),
      collapsible: true,
      expanded: _expanded,
      onToggle: () => setState(() => _expanded = !_expanded),
      trailing: TextButton(
        onPressed: widget.onEdit,
        child: Text(_expanded ? 'Edit' : 'Change'),
      ),
      titleSuffix: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: ready ? const Color(0xFF047857) : const Color(0xFF94A3B8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (!ready)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Add at least ${CertificateEventSignatoryConfig.minimumSignatories} signatories to generate certificates.',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
            ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List<Widget>.generate(configured, (int i) => _SignatoryCard(slot: slots[i])),
          ),
        ],
      ),
    );
  }
}

class _SignatoryCard extends StatelessWidget {
  const _SignatoryCard({required this.slot});

  final CertificateSignatorySlotDraft slot;

  @override
  Widget build(BuildContext context) {
    final bytes = slot.signatureBytes;
    final bool hasSig = bytes != null && bytes.isNotEmpty;
    final String name = slot.name.trim().isEmpty ? '—' : slot.name.trim();
    final String designation = slot.designation.trim();

    return Container(
      width: 200,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            height: 36,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: hasSig
                ? Image.memory(bytes, height: 32, fit: BoxFit.contain)
                : const Text(
                    'Signature',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          if (designation.isNotEmpty)
            Text(
              designation,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
            ),
        ],
      ),
    );
  }
}
