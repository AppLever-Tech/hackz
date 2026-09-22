import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/exports/certificate/certificate_data.dart';
import 'package:hackz/features/exports/certificate/certificate_document_builder.dart';
import 'package:hackz/features/exports/certificate/certificate_type.dart';

/// Generates a participation PDF using `participation_background.png`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('write participation preview PDF', () async {
    final Directory outDir = Directory('build/certificate_preview');
    outDir.createSync(recursive: true);
    final File outFile = File('${outDir.path}/participation_preview.pdf');

    final List<int> bytes = await CertificateDocumentBuilder.renderCertificates(
      <CertificateData>[
        const CertificateData(
          certificateType: CertificateType.participation,
          recipientType: CertificateRecipientType.team,
          recipientName: 'Team Innovators',
          organisationName: 'Sample College of Engineering',
          eventName: 'Ideathon 2026',
          eventTemplateLabel: 'Ideathon',
          eventDateLabel: '18 September 2026',
          submissionTitle: 'AI-Based Smart Water Management System',
          submissionLabel: 'Idea',
          signatories: <CertificateSignatory>[
            CertificateSignatory(name: 'Prof. S. K. Rai', designation: 'Faculty Coordinator'),
            CertificateSignatory(name: 'Dr. Ananth Rao', designation: 'Director'),
          ],
        ),
      ],
    );

    await outFile.writeAsBytes(bytes);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(outFile.existsSync(), isTrue);
  });
}
