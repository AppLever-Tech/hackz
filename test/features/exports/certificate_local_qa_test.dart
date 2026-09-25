import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/exports/certificate/certificate_data.dart';
import 'package:hackz/features/exports/certificate/certificate_document_builder.dart';
import 'package:hackz/features/exports/certificate/certificate_event_signatory_config.dart';
import 'package:hackz/features/exports/certificate/certificate_event_signatory_store.dart';
import 'package:hackz/features/exports/certificate/certificate_image_processing.dart';
import 'package:hackz/features/exports/certificate/certificate_pdf_assets.dart';
import 'package:hackz/features/exports/certificate/certificate_type.dart';
import 'package:image/image.dart' as img;

import 'certificate_test_fixtures.dart';

/// Local certificate PDF QA — run before deploying to Firebase hosting.
///
/// ```powershell
/// cd d:\Vinay\code\androidstudio\hackz
/// flutter test test/features/exports/certificate_local_qa_test.dart
/// ```
///
/// Open outputs under `build/certificate_preview/`:
/// - `participation_college_logo_only.pdf` — top-right logo + name
/// - `participation_signatures_cream_scan.pdf` — signatory scans (cream paper)
/// - `participation_full_branding.pdf` — logo + processed signatures (all types)
/// - `participation_name_only_long.pdf` — no logo; multi-line college name (top band symmetry)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String orgName = 'Prajna College of Engineering';
  const String eventName = 'Ideathon 2026';
  const String eventDate = '18 September 2026';
  const String submission = 'Smart Campus Water Analytics';

  Future<Directory> previewDir() async {
    final Directory dir = Directory('build/certificate_preview');
    dir.createSync(recursive: true);
    return dir;
  }

  Future<void> writePdf(String fileName, List<int> bytes) async {
    final Directory dir = await previewDir();
    await File('${dir.path}/$fileName').writeAsBytes(bytes);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  }

  group('Certificate local QA — image pipeline asserts', () {
    test('cream signature scan loses opaque background after prepareCertificateEmbed', () {
      final Uint8List raw = CertificateTestFixtures.creamSignatureScanPng();
      final Uint8List out = CertificateImageProcessing.prepareCertificateEmbed(raw);
      final img.Image? decoded = img.decodeImage(out);
      expect(decoded, isNotNull);
      expect(decoded!.getPixel(0, 0).a.toInt(), 0);
      expect(decoded.getPixel(100, 36).a.toInt(), 255);
    });

    test('signatory draft → PDF images uses processed signature bytes', () {
      final Uint8List raw = CertificateTestFixtures.ivorySignatureScanPng();
      final Uint8List processed = CertificateTestFixtures.signatureBytesForPdf(raw);
      final CertificateEventSignatoryDraft draft = CertificateEventSignatoryDraft(
        signatoryCount: 2,
        slots: <CertificateSignatorySlotDraft>[
          CertificateSignatorySlotDraft(
            name: 'Dr. Sample One',
            designation: 'Principal',
            signatureBase64: base64Encode(processed),
          ),
          const CertificateSignatorySlotDraft(name: 'Prof. Two', designation: 'Coordinator'),
        ],
      );
      final List<CertificateSignatory> signatories =
          CertificateEventSignatoryConfig.toPdfSignatories(draft);
      expect(signatories.first.signatureImage, isNotNull);
    });
  });

  group('Certificate local QA — write preview PDFs', () {
    test('participation_name_only_long.pdf', () async {
      const String longOrg =
          'National Institute of Technology Karnataka Surathkal Directorate of Innovation';
      final List<int> bytes = await CertificateDocumentBuilder.renderCertificates(
        <CertificateData>[
          const CertificateData(
            certificateType: CertificateType.participation,
            recipientType: CertificateRecipientType.team,
            recipientName: 'Team Innovators',
            organisationName: longOrg,
            eventName: eventName,
            eventTemplateLabel: 'Ideathon',
            eventDateLabel: eventDate,
            submissionTitle: submission,
            submissionLabel: 'Idea',
          ),
        ],
      );
      await writePdf('participation_name_only_long.pdf', bytes);
    });

    test('participation_college_logo_only.pdf', () async {
      final Uint8List logoPng = await CertificateTestFixtures.collegeLogoFromPrimaryBrandAsset();
      final List<int> bytes = await CertificateDocumentBuilder.renderCertificates(
        <CertificateData>[
          CertificateData(
            certificateType: CertificateType.participation,
            recipientType: CertificateRecipientType.team,
            recipientName: 'Team Innovators',
            organisationName: orgName,
            organisationLogo: CertificateData.memoryImageFromBytes(logoPng),
            eventName: eventName,
            eventTemplateLabel: 'Ideathon',
            eventDateLabel: eventDate,
            submissionTitle: submission,
            submissionLabel: 'Idea',
          ),
        ],
      );
      await writePdf('participation_college_logo_only.pdf', bytes);
    });

    test('participation_signatures_cream_scan.pdf', () async {
      final Uint8List sig = CertificateTestFixtures.signatureBytesForPdf(
        CertificateTestFixtures.creamSignatureScanPng(),
      );
      final List<int> bytes = await CertificateDocumentBuilder.renderCertificates(
        <CertificateData>[
          CertificateData(
            certificateType: CertificateType.participation,
            recipientType: CertificateRecipientType.team,
            recipientName: 'Team Innovators',
            organisationName: orgName,
            eventName: eventName,
            eventTemplateLabel: 'Ideathon',
            eventDateLabel: eventDate,
            submissionTitle: submission,
            submissionLabel: 'Idea',
            signatories: <CertificateSignatory>[
              CertificateSignatory(
                name: 'Dr. Sample One',
                designation: 'Principal',
                signatureImage: CertificatePdfAssets.memoryImageForCertificateEmbed(sig),
              ),
              CertificateSignatory(
                name: 'Prof. Sample Two',
                designation: 'Coordinator',
                signatureImage: CertificatePdfAssets.memoryImageForCertificateEmbed(sig),
              ),
            ],
          ),
        ],
      );
      await writePdf('participation_signatures_cream_scan.pdf', bytes);
      await File('${(await previewDir()).path}/signature_cream_processed.png').writeAsBytes(sig);
    });

    test('participation_full_branding.pdf (+ winner & runner_up)', () async {
      final Uint8List logoPng = await CertificateTestFixtures.collegeLogoFromPrimaryBrandAsset();
      final Uint8List sig = CertificateTestFixtures.signatureBytesForPdf(
        CertificateTestFixtures.creamSignatureScanPng(),
      );
      final List<CertificateSignatory> signatories = <CertificateSignatory>[
        CertificateSignatory(
          name: 'Dr. Sample One',
          designation: 'Principal',
          signatureImage: CertificatePdfAssets.memoryImageForCertificateEmbed(sig),
        ),
        CertificateSignatory(
          name: 'Prof. Sample Two',
          designation: 'Coordinator',
          signatureImage: CertificatePdfAssets.memoryImageForCertificateEmbed(sig),
        ),
      ];

      final Directory dir = await previewDir();
      for (final (String file, CertificateType type) in <(String, CertificateType)>[
        ('participation_full_branding.pdf', CertificateType.participation),
        ('winner_full_branding.pdf', CertificateType.winner),
        ('runner_up_full_branding.pdf', CertificateType.runnerUp),
      ]) {
        final List<int> bytes = await CertificateDocumentBuilder.renderCertificates(
          <CertificateData>[
            CertificateData(
              certificateType: type,
              recipientType: CertificateRecipientType.team,
              recipientName: 'Team Innovators',
              organisationName: orgName,
              organisationLogo: CertificateData.memoryImageFromBytes(logoPng),
              eventName: eventName,
              eventTemplateLabel: 'Ideathon',
              eventDateLabel: eventDate,
              submissionTitle: submission,
              submissionLabel: 'Idea',
              achievementLabel: switch (type) {
                CertificateType.winner => 'First Place',
                CertificateType.runnerUp => 'Second Place',
                CertificateType.participation => '',
              },
              signatories: signatories,
            ),
          ],
        );
        await File('${dir.path}/$file').writeAsBytes(bytes);
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      }
    });
  });
}
