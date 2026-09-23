import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/exports/certificate/certificate_event_signatory_config.dart';
import 'package:hackz/features/exports/certificate/certificate_event_signatory_store.dart';

void main() {
  group('CertificateEventSignatoryConfig', () {
    test('requires two named signatories', () {
      expect(CertificateEventSignatoryConfig.meetsMinimum(null), isFalse);
      expect(
        CertificateEventSignatoryConfig.meetsMinimum(
          const CertificateEventSignatoryDraft(
            slots: <CertificateSignatorySlotDraft>[
              CertificateSignatorySlotDraft(name: 'A'),
            ],
          ),
        ),
        isFalse,
      );
      expect(
        CertificateEventSignatoryConfig.meetsMinimum(
          const CertificateEventSignatoryDraft(
            slots: <CertificateSignatorySlotDraft>[
              CertificateSignatorySlotDraft(name: 'A'),
              CertificateSignatorySlotDraft(name: 'B'),
            ],
          ),
        ),
        isTrue,
      );
    });

    test('third signatory included when count is 3', () {
      final CertificateEventSignatoryDraft draft = CertificateEventSignatoryDraft(
        signatoryCount: 3,
        slots: <CertificateSignatorySlotDraft>[
          const CertificateSignatorySlotDraft(name: 'A'),
          const CertificateSignatorySlotDraft(name: 'B'),
          const CertificateSignatorySlotDraft(name: 'C'),
        ],
      );
      expect(CertificateEventSignatoryConfig.toPdfSignatories(draft).length, 3);
    });
  });
}
