import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/exports/certificate/certificate_data.dart';
import 'package:hackz/features/exports/certificate/certificate_document_builder.dart';
import 'package:hackz/features/exports/certificate/certificate_organisation_branding.dart';
import 'package:hackz/features/exports/certificate/certificate_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CertificateOrganisationBranding font sizing', () {
    const CertificateOrganisationBrandingLayout layout =
        CertificateOrganisationBrandingLayout.participationTopRight;

    test('short name keeps larger size without logo', () {
      final double size = CertificateOrganisationBranding.fontSizeForName(
        'Prajna College',
        layout,
        withLogo: false,
      );
      expect(size, layout.nameOnlyBaseSize);
    });

    test('long name scales down with logo', () {
      final double shortSize = CertificateOrganisationBranding.fontSizeForName(
        'National Institute',
        layout,
        withLogo: true,
      );
      final double longSize = CertificateOrganisationBranding.fontSizeForName(
        'National Institute of Technology and Advanced Sciences Directorate',
        layout,
        withLogo: true,
      );
      expect(longSize, lessThan(shortSize));
      expect(longSize, greaterThanOrEqualTo(layout.nameWithLogoMinSize));
    });
  });

  group('CertificateOrganisationBranding PDF smoke', () {
    Future<List<int>> render({required String org, Uint8List? logoBytes}) async {
      return CertificateDocumentBuilder.renderCertificates(
        <CertificateData>[
          CertificateData(
            certificateType: CertificateType.participation,
            recipientType: CertificateRecipientType.team,
            recipientName: 'Team Alpha',
            organisationName: org,
            organisationLogo: CertificateData.memoryImageFromBytes(logoBytes),
            eventName: 'Ideathon 2026',
            eventTemplateLabel: 'Ideathon',
            eventDateLabel: '18 September 2026',
            submissionTitle: 'Smart Campus',
            submissionLabel: 'Idea',
          ),
        ],
      );
    }

    test('short name without logo', () async {
      final List<int> bytes = await render(org: 'Prajna College');
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    });

    test('long name without logo', () async {
      final List<int> bytes = await render(
        org: 'National Institute of Technology Karnataka Surathkal Directorate of Innovation',
      );
      expect(bytes.isNotEmpty, true);
    });

    test('long name with logo bytes placeholder empty skips logo block', () async {
      final List<int> bytes = await render(org: 'Sample College of Engineering', logoBytes: null);
      expect(bytes.isNotEmpty, true);
    });
  });
}
