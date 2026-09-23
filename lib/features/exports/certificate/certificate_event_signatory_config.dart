import '../../events/exports/event_certificates_export_provider.dart';
import 'certificate_data.dart';
import 'certificate_event_signatory_store.dart';

/// Event-level certificate signatory validation and PDF/export mapping.
abstract final class CertificateEventSignatoryConfig {
  CertificateEventSignatoryConfig._();

  static const int minimumSignatories = 2;

  /// A signatory slot is valid when a certificate name is present.
  static bool isValidSlot(CertificateSignatorySlotDraft slot) => slot.name.trim().isNotEmpty;

  static int validCount(CertificateEventSignatoryDraft draft) {
    final int active = draft.signatoryCount.clamp(minimumSignatories, 3);
    int count = 0;
    for (int i = 0; i < active; i++) {
      if (i < draft.slots.length && isValidSlot(draft.slots[i])) count++;
    }
    return count;
  }

  static bool meetsMinimum(CertificateEventSignatoryDraft? draft) {
    if (draft == null) return false;
    return validCount(draft) >= minimumSignatories;
  }

  static List<CertificateSignatorySlotDraft> normalizedSlots(CertificateEventSignatoryDraft? draft) {
    final List<CertificateSignatorySlotDraft> slots = List<CertificateSignatorySlotDraft>.generate(
      3,
      (_) => const CertificateSignatorySlotDraft(),
    );
    if (draft == null) return slots;
    for (int i = 0; i < slots.length && i < draft.slots.length; i++) {
      slots[i] = draft.slots[i];
    }
    return slots;
  }

  static int normalizedCount(CertificateEventSignatoryDraft? draft) {
    final int raw = draft?.signatoryCount ?? minimumSignatories;
    return raw.clamp(minimumSignatories, 3);
  }

  static List<CertificateSignatory> toPdfSignatories(CertificateEventSignatoryDraft? draft) {
    final int count = normalizedCount(draft);
    final List<CertificateSignatorySlotDraft> slots = normalizedSlots(draft);
    return List<CertificateSignatory>.generate(count, (int i) {
      final CertificateSignatorySlotDraft slot = slots[i];
      return CertificateSignatory(
        name: slot.name.trim(),
        designation: slot.designation.trim(),
        signatureImage: CertificateData.memoryImageFromBytes(slot.signatureBytes),
      );
    });
  }

  static List<EventCertificateSignatory> toExportSignatories(CertificateEventSignatoryDraft? draft) {
    final int count = normalizedCount(draft);
    final List<CertificateSignatorySlotDraft> slots = normalizedSlots(draft);
    return List<EventCertificateSignatory>.generate(count, (int i) {
      final CertificateSignatorySlotDraft slot = slots[i];
      final bytes = slot.signatureBytes;
      return EventCertificateSignatory(
        name: slot.name.trim(),
        designation: slot.designation.trim(),
        signatureBytes: bytes == null ? null : List<int>.from(bytes),
      );
    });
  }
}
