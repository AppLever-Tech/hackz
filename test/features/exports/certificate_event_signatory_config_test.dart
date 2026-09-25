import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/exports/certificate/certificate_event_signatory_config.dart';
import 'package:hackz/features/exports/certificate/certificate_event_signatory_store.dart';
import 'package:hackz/features/exports/certificate/certificate_image_processing.dart';

import 'certificate_test_fixtures.dart';

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

    test('toPdfSignatories runs certificate embed pipeline on signature bytes', () {
      final Uint8List raw = CertificateTestFixtures.creamSignatureScanPng();
      final CertificateEventSignatoryDraft draft = CertificateEventSignatoryDraft(
        slots: <CertificateSignatorySlotDraft>[
          CertificateSignatorySlotDraft(
            name: 'Dr. A',
            signatureBase64: base64Encode(raw),
          ),
          const CertificateSignatorySlotDraft(name: 'Dr. B'),
        ],
      );
      final signatories = CertificateEventSignatoryConfig.toPdfSignatories(draft);
      expect(signatories.first.signatureImage, isNotNull);
      final Uint8List processed = CertificateImageProcessing.prepareCertificateEmbed(raw);
      expect(processed, isNotEmpty);
    });
  });
}
