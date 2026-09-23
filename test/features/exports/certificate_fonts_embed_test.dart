import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/exports/certificate/certificate_data.dart';
import 'package:hackz/features/exports/certificate/certificate_document_builder.dart';
import 'package:hackz/features/exports/certificate/certificate_fonts.dart';
import 'package:hackz/features/exports/certificate/certificate_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String org = 'Sample College of Engineering';
  const String event = 'Ideathon 2026';
  const String date = '18 September 2026';
  const String idea = 'AI-Based Smart Water Management System';

  Future<List<int>> render(CertificateType type) {
    return CertificateDocumentBuilder.renderCertificates(
      <CertificateData>[
        CertificateData(
          certificateType: type,
          recipientType: CertificateRecipientType.team,
          recipientName: 'Team Innovators With A Very Long Name For Fitting',
          organisationName: org,
          eventName: event,
          eventTemplateLabel: 'Ideathon',
          eventDateLabel: date,
          submissionTitle: idea,
          submissionLabel: 'Idea',
          achievementLabel: type == CertificateType.winner
              ? 'First Place'
              : type == CertificateType.runnerUp
                  ? 'Second Place'
                  : '',
        ),
      ],
    );
  }

  test('embeds certificate fonts and writes participation winner runner-up PDFs', () async {
    await CertificateFonts.load();
    final Directory out = Directory('build/certificate_font_preview');
    out.createSync(recursive: true);

    final List<(String, CertificateType)> samples = <(String, CertificateType)>[
      ('participation', CertificateType.participation),
      ('winner', CertificateType.winner),
      ('runner_up', CertificateType.runnerUp),
    ];

    for (final (String name, CertificateType type) in samples) {
      final List<int> bytes = await render(type);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      if (type == CertificateType.participation) {
        final String pdfText = String.fromCharCodes(bytes);
        expect(pdfText.contains('PlayfairDisplay'), isTrue);
        expect(pdfText.contains('GreatVibes'), isTrue);
        expect(pdfText.contains('Inter'), isTrue);
      }
      await File('${out.path}/$name.pdf').writeAsBytes(bytes);
    }
  });
}
