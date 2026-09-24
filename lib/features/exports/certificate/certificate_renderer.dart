import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'certificate_data.dart';
import 'certificate_fonts.dart';
import 'certificate_organisation_branding.dart';
import 'certificate_render_context.dart';
import 'certificate_submission_terminology.dart';
import 'certificate_theme.dart';
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
        if (context.participationBackground != null)
          pw.Positioned.fill(
            child: pw.Image(context.participationBackground!, fit: pw.BoxFit.cover),
          )
        else
          pw.Positioned.fill(child: pw.Container(color: CertificateTheme.ivory)),
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
  static const double _participationHackzLogoHeight = 72;
  static const double _participationHackzSlotWidth = 168;
  static const double _participationLeftBandWidth = 210;

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
              width: _participationLeftBandWidth,
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
            pw.Expanded(
              child: pw.SizedBox(
                height: 78,
                child: _headerCenterContent(data, fonts, context),
              ),
            ),
            CertificateOrganisationBranding.build(
              fonts: fonts,
              organisationName: data.organisationName,
              organisationLogo: data.organisationLogo,
              layout: CertificateOrganisationBrandingLayout.participationTopRight,
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
        return _headerOverlayImage(context.runnerUpOverlay);
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
        _certificateSignatoryFooter(signatories, fonts),
        pw.SizedBox(height: _participationFooterBottomGap),
      ],
    );
  }

  /// ~2 line gaps + 3 additional line heights below designation row.
  static const double _participationFooterBottomGap = 56;

  /// Horizontal gap between signatory blocks and center tagline (fixed layout).
  static const double _signatoryGapFromCenter = 12;

  static const double _participationSignatorySideWidth = 132;
  static const double _participationSignatoryCenterWidth = 128;

  static pw.Widget _certificateSignatoryFooter(
    List<CertificateSignatory> signatories,
    CertificateFonts fonts,
  ) {
    if (signatories.length >= 3 && _hasSignatoryContent(signatories[2])) {
      return _threeSignatoryFooter(signatories, fonts);
    }
    final CertificateSignatory left = signatories[0];
    final CertificateSignatory right = signatories[1];
    const double lineWidth = _participationSignatorySideWidth;

    pw.Widget signatureLineBlock(CertificateSignatory signatory) {
      return pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: <pw.Widget>[
          if (signatory.signatureImage != null)
            pw.SizedBox(
              height: 20,
              child: pw.Image(signatory.signatureImage!, fit: pw.BoxFit.contain),
            ),
          pw.Container(width: lineWidth, height: 0.6, color: CertificateTheme.ink),
        ],
      );
    }

    pw.Widget centeredText(String text, pw.TextStyle style, {int maxLines = 2}) {
      return pw.Text(
        text,
        style: style,
        textAlign: pw.TextAlign.center,
        maxLines: maxLines,
      );
    }

    pw.Widget signatoryTextBlock(
      String text,
      pw.TextStyle style, {
      double top = 4,
      int maxLines = 1,
    }) {
      if (text.isEmpty) return pw.SizedBox();
      return pw.Padding(
        padding: pw.EdgeInsets.only(top: top),
        child: pw.Text(
          text,
          style: style,
          textAlign: pw.TextAlign.center,
          maxLines: maxLines,
        ),
      );
    }

    pw.Widget footerRow({
      required pw.Widget left,
      required pw.Widget center,
      required pw.Widget right,
    }) {
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          pw.SizedBox(
            width: _participationSignatorySideWidth,
            child: pw.Align(alignment: pw.Alignment.topCenter, child: left),
          ),
          pw.SizedBox(width: _signatoryGapFromCenter),
          pw.SizedBox(
            width: _participationSignatoryCenterWidth,
            child: pw.Align(alignment: pw.Alignment.topCenter, child: center),
          ),
          pw.SizedBox(width: _signatoryGapFromCenter),
          pw.SizedBox(
            width: _participationSignatorySideWidth,
            child: pw.Align(alignment: pw.Alignment.topCenter, child: right),
          ),
        ],
      );
    }

    return pw.Column(
      children: <pw.Widget>[
        footerRow(
          left: signatureLineBlock(left),
          center: pw.SizedBox(),
          right: signatureLineBlock(right),
        ),
        footerRow(
          left: signatoryTextBlock(
            left.name.trim(),
            CertificateTheme.signatoryName(fonts, size: 11.5),
          ),
          center: centeredText(
            'IDEAS TODAY',
            CertificateTheme.participationTaglinePrimary(fonts),
            maxLines: 1,
          ),
          right: signatoryTextBlock(
            right.name.trim(),
            CertificateTheme.signatoryName(fonts, size: 11.5),
          ),
        ),
        footerRow(
          left: signatoryTextBlock(
            left.designation.trim(),
            CertificateTheme.signatoryTitle(fonts, size: 10),
            top: 3,
            maxLines: 2,
          ),
          center: centeredText(
            'A BRIGHTER TOMORROW',
            CertificateTheme.participationTaglineSecondary(fonts),
            maxLines: 1,
          ),
          right: signatoryTextBlock(
            right.designation.trim(),
            CertificateTheme.signatoryTitle(fonts, size: 10),
            top: 3,
            maxLines: 2,
          ),
        ),
      ],
    );
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

  static bool _hasSignatoryContent(CertificateSignatory signatory) {
    return signatory.name.trim().isNotEmpty ||
        signatory.designation.trim().isNotEmpty ||
        signatory.signatureImage != null;
  }

  static pw.Widget _threeSignatoryFooter(List<CertificateSignatory> signatories, CertificateFonts fonts) {
    final CertificateSignatory left = signatories[0];
    final CertificateSignatory right = signatories[1];
    final CertificateSignatory center = signatories[2];
    const double lineWidth = _participationSignatorySideWidth;

    pw.Widget signatureLineBlock(CertificateSignatory signatory) {
      return pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: <pw.Widget>[
          if (signatory.signatureImage != null)
            pw.SizedBox(
              height: 20,
              child: pw.Image(signatory.signatureImage!, fit: pw.BoxFit.contain),
            ),
          pw.Container(width: lineWidth, height: 0.6, color: CertificateTheme.ink),
        ],
      );
    }

    pw.Widget slot(CertificateSignatory signatory) {
      return pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: <pw.Widget>[
          signatureLineBlock(signatory),
          if (signatory.name.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                signatory.name.trim(),
                style: CertificateTheme.signatoryName(fonts, size: 11.5),
                textAlign: pw.TextAlign.center,
                maxLines: 1,
              ),
            ),
          if (signatory.designation.trim().isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 3),
              child: pw.Text(
                signatory.designation.trim(),
                style: CertificateTheme.signatoryTitle(fonts, size: 10),
                textAlign: pw.TextAlign.center,
                maxLines: 2,
              ),
            ),
        ],
      );
    }

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.SizedBox(width: _participationSignatorySideWidth, child: slot(left)),
        pw.SizedBox(width: _signatoryGapFromCenter),
        pw.SizedBox(width: _participationSignatoryCenterWidth, child: slot(center)),
        pw.SizedBox(width: _signatoryGapFromCenter),
        pw.SizedBox(width: _participationSignatorySideWidth, child: slot(right)),
      ],
    );
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
