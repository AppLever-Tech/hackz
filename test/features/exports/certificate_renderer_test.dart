import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/exports/certificate/certificate_data.dart';
import 'package:hackz/features/exports/certificate/certificate_document_builder.dart';
import 'package:hackz/features/exports/certificate/certificate_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String org = 'Sample College of Engineering';
  const String event = 'Annual Innovation Summit 2026';
  const String dates = '12 Mar 2026 - 14 Mar 2026';

  group('Certificate PDF bytes', () {
    test('Ideathon participation (team)', () async {
      final List<int> bytes = await CertificateDocumentBuilder.renderCertificates(
        <CertificateData>[
          CertificateData(
            certificateType: CertificateType.participation,
            recipientType: CertificateRecipientType.team,
            recipientName: 'Team Alpha Innovators',
            organisationName: org,
            eventName: event,
            eventTemplateLabel: 'Ideathon',
            eventDateLabel: dates,
            submissionTitle: 'Smart Campus Navigation',
            submissionLabel: 'Idea',
          ),
        ],
      );
      expect(bytes.length, greaterThan(500));
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('Ideathon winner (team)', () async {
      final List<int> bytes = await CertificateDocumentBuilder.renderCertificates(
        <CertificateData>[
          CertificateData(
            certificateType: CertificateType.winner,
            recipientType: CertificateRecipientType.team,
            recipientName: 'Team Alpha Innovators',
            organisationName: org,
            eventName: event,
            eventTemplateLabel: 'Ideathon',
            eventDateLabel: dates,
            submissionTitle: 'Smart Campus Navigation',
            submissionLabel: 'Idea',
            achievementLabel: 'First Place',
            signatories: const <CertificateSignatory>[
              CertificateSignatory(name: 'Dr. A. Patil', designation: 'Head of Department'),
              CertificateSignatory(name: 'Prof. B. Rao', designation: 'Event Coordinator'),
            ],
          ),
        ],
      );
      expect(bytes.isNotEmpty, true);
    });

    test('Ideathon runner-up (team)', () async {
      final List<int> bytes = await CertificateDocumentBuilder.renderCertificates(
        <CertificateData>[
          CertificateData(
            certificateType: CertificateType.runnerUp,
            recipientType: CertificateRecipientType.team,
            recipientName: 'Team Beta Builders',
            organisationName: org,
            eventName: event,
            eventTemplateLabel: 'Ideathon',
            eventDateLabel: dates,
            submissionTitle: 'Energy Monitor',
            submissionLabel: 'Idea',
            achievementLabel: 'Second Place',
          ),
        ],
      );
      expect(bytes.isNotEmpty, true);
    });

    test('Hackathon participation uses Prototype label', () async {
      final List<int> bytes = await CertificateDocumentBuilder.renderCertificates(
        <CertificateData>[
          CertificateData(
            certificateType: CertificateType.participation,
            recipientType: CertificateRecipientType.team,
            recipientName: 'Hack Squad',
            organisationName: org,
            eventName: 'Inter-College Hackathon 2026',
            eventTemplateLabel: 'Hackathon',
            eventDateLabel: dates,
            submissionTitle: 'IoT Lab Kit',
            submissionLabel: 'Prototype',
          ),
        ],
      );
      expect(bytes.isNotEmpty, true);
    });

    test('Research Paper participation', () async {
      final List<int> bytes = await CertificateDocumentBuilder.renderCertificates(
        <CertificateData>[
          CertificateData(
            certificateType: CertificateType.participation,
            recipientType: CertificateRecipientType.team,
            recipientName: 'Research Cell 7',
            organisationName: org,
            eventName: 'Research Paper Evaluation 2026',
            eventTemplateLabel: 'Research Paper',
            eventDateLabel: dates,
            submissionTitle: 'Edge ML for Agriculture',
            submissionLabel: 'Paper',
          ),
        ],
      );
      expect(bytes.isNotEmpty, true);
    });

    test('Individual recipient with team line', () async {
      final List<int> bytes = await CertificateDocumentBuilder.renderCertificates(
        <CertificateData>[
          CertificateData(
            certificateType: CertificateType.participation,
            recipientType: CertificateRecipientType.individual,
            recipientName: 'Priya Sharma',
            teamName: 'Team Alpha Innovators',
            organisationName: org,
            eventName: event,
            eventTemplateLabel: 'Ideathon',
            eventDateLabel: dates,
            submissionTitle: 'Smart Campus Navigation',
            submissionLabel: 'Idea',
          ),
        ],
      );
      expect(bytes.isNotEmpty, true);
    });
  });
}
