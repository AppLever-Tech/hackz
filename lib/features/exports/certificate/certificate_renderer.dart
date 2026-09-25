import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'certificate_data.dart';
import 'certificate_fonts.dart';
import 'certificate_organisation_branding.dart';
import 'certificate_render_context.dart';
import 'certificate_submission_terminology.dart';
import 'certificate_theme.dart';
import 'certificate_signatory_footer.dart';
import 'certificate_visual_variant.dart';
import 'certificate_type.dart';

/// Data-driven certificate page builder (participation, winner, runner-up).
abstract final class CertificateRenderer {
  CertificateRenderer._();

  static pw.Widget buildPage({
    required CertificateData data,
    required CertificateRenderContext context,
  }) {
    final CertificateVisualVariant variant = CertificateVisualVariant.forType(data.certificateType);
    final CertificateFonts fonts = context.fonts;
    final List<CertificateSignatory> signatories = _normalizedSignatories(data.signatories);

      return pw.Stack(
        children: <pw.Widget>[
        _fullPageBackground(context),
        _certificateTopBand(data, fonts, context),
          pw.Positioned.fill(
            child: pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(44, 134, 44, 22),
            child: _certificateMainColumn(
                data: data,
                context: context,
                variant: variant,
                fonts: fonts,
                signatories: signatories,
              ),
            ),
          ),
        ],
      );
  }

  static const double _participationBandTop = 26;
  static const double _participationHackzLogoHeight = 92;
  static const double _participationHackzSlotWidth = 176;
  static const double _participationSideBandWidth = 210;
  static const double _participationInnerGutter = 16;

  /// Top band: Hackz logo, centered title or achievement overlay, college branding.
  static pw.Widget _certificateTopBand(
    CertificateData data,
    CertificateFonts fonts,
    CertificateRenderContext context,
  ) {
    final pw.ImageProvider? hackz = data.hackzLogo;
    return pw.Positioned(
      top: _participationBandTop,
      left: 0,
      right: 0,
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 28),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: <pw.Widget>[
            pw.SizedBox(
              width: _participationSideBandWidth,
              height: _participationHackzLogoHeight,
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: hackz != null
                    ? pw.SizedBox(
                        height: _participationHackzLogoHeight,
                        width: _participationHackzSlotWidth,
                        child: pw.Image(hackz, fit: pw.BoxFit.contain),
                      )
                    : pw.Text('HACKZ', style: CertificateTheme.participationOrgName(fonts)),
              ),
            ),
            pw.SizedBox(width: _participationInnerGutter),
            pw.Expanded(
              child: pw.SizedBox(
                height: _participationHackzLogoHeight,
                child: _headerCenterContent(data, fonts, context),
              ),
            ),
            pw.SizedBox(width: _participationInnerGutter),
            CertificateOrganisationBranding.build(
              fonts: fonts,
              organisationName: data.organisationName,
              organisationLogo: data.organisationLogo,
              layout: CertificateOrganisationBrandingLayout.participationTopRight,
              bandWidth: _participationSideBandWidth,
              bandHeight: _participationHackzLogoHeight,
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _headerCenterContent(
    CertificateData data,
    CertificateFonts fonts,
    CertificateRenderContext context,
  ) {
    switch (data.certificateType) {
      case CertificateType.participation:
        return pw.Stack(
                  alignment: pw.Alignment.topCenter,
                  children: <pw.Widget>[
                    pw.Text(
                      'CERTIFICATE OF',
                      style: CertificateTheme.certificateOfLabel(fonts),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Positioned(
                      top: 23,
                      left: 0,
                      right: 0,
                      child: pw.Text(
                        'PARTICIPATION',
                        style: CertificateTheme.participationTitle(fonts, size: 34),
                        textAlign: pw.TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                  ],
        );
      case CertificateType.winner:
        return _headerOverlayImage(context.winnerOverlay);
      case CertificateType.runnerUp:
        return _headerOverlayImage(context.secondPlaceOverlay ?? context.runnerUpOverlay);
      case CertificateType.thirdPlace:
        return _headerOverlayImage(context.thirdPlaceOverlay);
    }
  }

  static pw.Widget _headerOverlayImage(pw.MemoryImage? overlay) {
    if (overlay == null) return pw.SizedBox();
    return pw.Center(
      child: pw.Image(overlay, fit: pw.BoxFit.contain),
    );
  }

  static pw.Widget _certificateMainColumn({
    required CertificateData data,
    required CertificateRenderContext context,
    required CertificateVisualVariant variant,
    required CertificateFonts fonts,
    required List<CertificateSignatory> signatories,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: <pw.Widget>[
        pw.Text(
          'This certificate is proudly presented to',
          style: CertificateTheme.participationIntro(fonts),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 10),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12),
          child: pw.Text(
            data.recipientName.trim(),
            style: CertificateTheme.recipientScript(
              fonts,
              CertificateTheme.recipientFontSize(data.recipientName, participation: true),
            ),
            textAlign: pw.TextAlign.center,
            maxLines: 3,
          ),
        ),
        if (_memberOfLine(data).isNotEmpty) ...<pw.Widget>[
          pw.SizedBox(height: 6),
          pw.Text(
            _memberOfLine(data),
            style: CertificateTheme.participationBody(fonts),
            textAlign: pw.TextAlign.center,
          ),
        ],
        pw.SizedBox(height: 10),
        _recipientDivider(),
        pw.SizedBox(height: 12),
        _certificateBodyLines(data, fonts, variant),
        pw.Spacer(),
        CertificateSignatoryFooter.build(signatories, fonts),
        pw.SizedBox(height: _certificateFooterBottomGap),
      ],
    );
  }

  /// ~2 line gaps + 3 additional line heights below designation row.
  static const double _certificateFooterBottomGap = 56;

  static pw.Widget _fullPageBackground(CertificateRenderContext context) {
    if (context.participationBackground != null) {
      return pw.Positioned.fill(
        child: pw.Image(context.participationBackground!, fit: pw.BoxFit.cover),
      );
    }
    return pw.Positioned.fill(child: pw.Container(color: CertificateTheme.ivory));
  }

  static pw.Widget _certificateBodyLines(
    CertificateData data,
    CertificateFonts fonts,
    CertificateVisualVariant variant,
  ) {
    final String event = data.eventName.trim();
    final String title = data.submissionTitle.trim();
    final String date = data.eventDateLabel.trim();
    const double bodySize = 16;
    const double eventNameSize = 18;
    const double ideaTitleSize = 17;
    const double recognitionSize = 13;

    pw.Widget line(String text, pw.TextStyle style, {int maxLines = 2}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Text(text, style: style, textAlign: pw.TextAlign.center, maxLines: maxLines),
      );
    }

    final bool participation = data.certificateType == CertificateType.participation;
    final String submissionLine = participation
        ? CertificateSubmissionTerminology.presentingPhrase(data.submissionLabel)
        : CertificateSubmissionTerminology.forThePhrase(data.submissionLabel);

    return pw.Column(
      children: <pw.Widget>[
        line(variant.bodyLeadLine, CertificateTheme.participationBody(fonts, size: bodySize)),
        if (event.isNotEmpty)
          line(event, CertificateTheme.bodyBold(fonts, size: eventNameSize), maxLines: 2),
        line(submissionLine, CertificateTheme.participationBody(fonts, size: bodySize)),
        if (title.isNotEmpty)
          line(
            '"$title"',
            CertificateTheme.bodySemiBold(fonts, size: ideaTitleSize),
            maxLines: 3,
          ),
        if (date.isNotEmpty)
          line(
            'held on $date',
            CertificateTheme.participationBody(fonts, size: bodySize),
          ),
        line(
          variant.bodyRecognitionLine,
          CertificateTheme.participationBody(fonts, size: recognitionSize),
          maxLines: 3,
        ),
      ],
    );
  }

  /// ~one third of the main column width (A4 landscape minus horizontal padding).
  static const double _recipientDividerWidth = 252;

  static pw.Widget _recipientDivider() {
    return pw.Center(
      child: pw.Container(
        width: _recipientDividerWidth,
        height: 0.6,
        color: PdfColor.fromInt(0xFFC9A227),
      ),
    );
  }

  static String _memberOfLine(CertificateData data) {
    if (data.recipientType != CertificateRecipientType.individual) return '';
    final String team = data.teamName.trim();
    if (team.isEmpty) return '';
    return 'Member of $team';
  }

  static List<CertificateSignatory> _normalizedSignatories(List<CertificateSignatory> input) {
    final List<CertificateSignatory> list = List<CertificateSignatory>.from(input);
    while (list.length < 2) {
      list.add(const CertificateSignatory());
    }
    if (list.length >= 3) {
      return list.take(3).toList(growable: false);
    }
    return list.take(2).toList(growable: false);
  }
}
