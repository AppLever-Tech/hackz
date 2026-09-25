import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/exports/certificate/certificate_data.dart';
import 'package:hackz/features/exports/certificate/certificate_document_builder.dart';
import 'package:hackz/features/exports/certificate/certificate_type.dart';

/// Writes participation / winner / runner-up PDFs for manual visual QA.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String org = 'Sample College of Engineering';
  const String event = 'Ideathon 2026';
  const String date = '18 September 2026';
  const String title = 'AI-Based Smart Water Management System';
  const List<CertificateSignatory> signatories = <CertificateSignatory>[
    CertificateSignatory(name: 'Prof. S. K. Rai', designation: 'Faculty Coordinator'),
    CertificateSignatory(name: 'Dr. Ananth Rao', designation: 'Director'),
  ];

  test('write certificate visual samples (participation, winner, runner-up)', () async {
    final Directory outDir = Directory('build/certificate_preview');
    outDir.createSync(recursive: true);

    final List<(String fileName, CertificateType type)> samples = <(String, CertificateType)>[
      ('participation_preview.pdf', CertificateType.participation),
      ('winner_preview.pdf', CertificateType.winner),
      ('second_place_preview.pdf', CertificateType.runnerUp),
      ('third_place_preview.pdf', CertificateType.thirdPlace),
    ];

    for (final (String fileName, CertificateType type) in samples) {
      final List<int> bytes = await CertificateDocumentBuilder.renderCertificates(
        <CertificateData>[
          CertificateData(
            certificateType: type,
            recipientType: CertificateRecipientType.team,
            recipientName: 'Team Innovators',
            organisationName: org,
            eventName: event,
            eventTemplateLabel: 'Ideathon',
            eventDateLabel: date,
            submissionTitle: title,
            submissionLabel: 'Idea',
            achievementLabel: type == CertificateType.winner
                ? '1st Place'
                : type == CertificateType.runnerUp
                    ? '2nd Place'
                    : type == CertificateType.thirdPlace
                        ? '3rd Place'
                        : '',
            signatories: signatories,
          ),
        ],
      );
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      await File('${outDir.path}/$fileName').writeAsBytes(bytes);
    }
  });
}
