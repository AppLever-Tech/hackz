import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'certificate_data.dart';
import 'certificate_fonts.dart';
import 'certificate_organisation_branding.dart';
import 'certificate_sample_a_render_context.dart';
import 'certificate_sample_a_theme.dart';
import 'certificate_sample_a_visual_variant.dart';
import 'certificate_type.dart';

/// Single data-driven Sample A certificate page builder (A1 / A2 / A3).
abstract final class CertificateSampleARenderer {
  CertificateSampleARenderer._();

  static pw.Widget buildPage({
    required CertificateData data,
    required CertificateSampleARenderContext context,
  }) {
    final CertificateVisualVariant variant = CertificateVisualVariant.forType(data.certificateType);
    final CertificateFonts fonts = context.fonts;
    final List<CertificateSignatory> signatories = _normalizedSignatories(data.signatories);

    if (_usesParticipationBackground(data, context)) {
      return pw.Stack(
        children: <pw.Widget>[
          pw.Positioned.fill(
            child: pw.Image(context.participationBackground!, fit: pw.BoxFit.cover),
          ),
          _participationTopBand(data, fonts),
          pw.Positioned.fill(
            child: pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(44, 134, 44, 22),
              child: _participationMainColumn(
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

    return pw.Stack(
      children: <pw.Widget>[
        pw.Container(color: CertificateSampleATheme.ivory),
        if (context.paperTexture != null)
          pw.Positioned.fill(
            child: pw.Opacity(
              opacity: 0.55,
              child: pw.Image(context.paperTexture!, fit: pw.BoxFit.cover),
            ),
          ),
        if (context.academicWatermark != null)
          pw.Positioned(
            left: 0,
            right: 0,
            bottom: 36,
            child: pw.Center(
              child: pw.Opacity(
                opacity: 0.22,
                child: pw.SizedBox(
                  height: 130,
                  child: pw.Image(context.academicWatermark!, fit: pw.BoxFit.contain),
                ),
              ),
            ),
          ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: variant.accent, width: 1.6),
            ),
            padding: const pw.EdgeInsets.all(7),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: CertificateSampleATheme.innerLine, width: 0.6),
              ),
              padding: const pw.EdgeInsets.fromLTRB(28, 20, 28, 18),
              child: _certificateContent(
                data: data,
                context: context,
                variant: variant,
                fonts: fonts,
                signatories: signatories,
                framed: true,
              ),
            ),
          ),
        ),
        ..._cornerDecorations(context, variant),
      ],
    );
  }

  static bool _usesParticipationBackground(CertificateData data, CertificateSampleARenderContext context) {
    return data.certificateType == CertificateType.participation && context.participationBackground != null;
  }

  static const double _participationBandTop = 26;
  static const double _participationHackzLogoHeight = 72;
  static const double _participationHackzSlotWidth = 168;
  static const double _participationLeftBandWidth = 210;

  /// Top band: Hackz logo (after corner), centered title, college name/logo aligned with logo row.
  static pw.Widget _participationTopBand(CertificateData data, CertificateFonts fonts) {
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
                    : pw.Text('HACKZ', style: CertificateSampleATheme.participationOrgName(fonts)),
              ),
            ),
            pw.Expanded(
              child: pw.SizedBox(
                height: 78,
                child: pw.Stack(
                  alignment: pw.Alignment.topCenter,
                  children: <pw.Widget>[
                    pw.Text(
                      'CERTIFICATE OF',
                      style: CertificateSampleATheme.certificateOfLabel(fonts),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.Positioned(
                      top: 23,
                      left: 0,
                      right: 0,
                      child: pw.Text(
                        'PARTICIPATION',
                        style: CertificateSampleATheme.participationTitle(fonts, size: 34),
                        textAlign: pw.TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
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

  static pw.Widget _participationMainColumn({
    required CertificateData data,
    required CertificateSampleARenderContext context,
    required CertificateVisualVariant variant,
    required CertificateFonts fonts,
    required List<CertificateSignatory> signatories,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: <pw.Widget>[
        pw.Text(
          'This certificate is proudly presented to',
          style: CertificateSampleATheme.participationIntro(fonts),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 10),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12),
          child: pw.Text(
            data.recipientName.trim(),
            style: CertificateSampleATheme.recipientScript(
              fonts,
              CertificateSampleATheme.recipientFontSize(data.recipientName, participation: true),
            ),
            textAlign: pw.TextAlign.center,
            maxLines: 3,
          ),
        ),
        if (_memberOfLine(data).isNotEmpty) ...<pw.Widget>[
          pw.SizedBox(height: 6),
          pw.Text(
            _memberOfLine(data),
            style: CertificateSampleATheme.participationBody(fonts),
            textAlign: pw.TextAlign.center,
          ),
        ],
        pw.SizedBox(height: 10),
        _recipientDivider(context, variant),
        pw.SizedBox(height: 14),
        _participationBodyLines(data, fonts),
        pw.Spacer(),
        _participationSignatoryFooter(signatories, fonts),
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

  static pw.Widget _participationSignatoryFooter(
    List<CertificateSignatory> signatories,
    CertificateFonts fonts,
  ) {
    final CertificateSignatory left = signatories[0];
    final CertificateSignatory right = signatories[1];
    const double lineWidth = _participationSignatorySideWidth;

    pw.Widget signatureLineBlock(CertificateSignatory signatory, {required bool leftSide}) {
      return pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: leftSide ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: <pw.Widget>[
          if (signatory.signatureImage != null)
            pw.SizedBox(
              height: 20,
              child: pw.Image(signatory.signatureImage!, fit: pw.BoxFit.contain),
            ),
          pw.Container(width: lineWidth, height: 0.6, color: CertificateSampleATheme.ink),
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
      required pw.TextAlign textAlign,
      double top = 4,
    }) {
      if (text.isEmpty) return pw.SizedBox();
      return pw.Padding(
        padding: pw.EdgeInsets.only(top: top),
        child: pw.Text(
          text,
          style: style,
          textAlign: textAlign,
          maxLines: 2,
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
            child: pw.Align(alignment: pw.Alignment.topRight, child: left),
          ),
          pw.SizedBox(width: _signatoryGapFromCenter),
          pw.SizedBox(
            width: _participationSignatoryCenterWidth,
            child: pw.Align(alignment: pw.Alignment.topCenter, child: center),
          ),
          pw.SizedBox(width: _signatoryGapFromCenter),
          pw.SizedBox(
            width: _participationSignatorySideWidth,
            child: pw.Align(alignment: pw.Alignment.topLeft, child: right),
          ),
        ],
      );
    }

    return pw.Column(
      children: <pw.Widget>[
        footerRow(
          left: signatureLineBlock(left, leftSide: true),
          center: pw.SizedBox(),
          right: signatureLineBlock(right, leftSide: false),
        ),
        footerRow(
          left: signatoryTextBlock(
            left.name.trim(),
            CertificateSampleATheme.signatoryName(fonts, size: 11.5),
            textAlign: pw.TextAlign.right,
          ),
          center: centeredText(
            'IDEAS TODAY',
            CertificateSampleATheme.participationTaglinePrimary(fonts),
            maxLines: 1,
          ),
          right: signatoryTextBlock(
            right.name.trim(),
            CertificateSampleATheme.signatoryName(fonts, size: 11.5),
            textAlign: pw.TextAlign.left,
          ),
        ),
        footerRow(
          left: signatoryTextBlock(
            left.designation.trim(),
            CertificateSampleATheme.signatoryTitle(fonts, size: 10),
            textAlign: pw.TextAlign.right,
            top: 3,
          ),
          center: centeredText(
            'A BRIGHTER TOMORROW',
            CertificateSampleATheme.participationTaglineSecondary(fonts),
            maxLines: 1,
          ),
          right: signatoryTextBlock(
            right.designation.trim(),
            CertificateSampleATheme.signatoryTitle(fonts, size: 10),
            textAlign: pw.TextAlign.left,
            top: 3,
          ),
        ),
      ],
    );
  }

  static String _presentingSubmissionPhrase(String submissionLabel) {
    final String label = submissionLabel.trim().toLowerCase();
    if (label.contains('prototype')) return 'and presenting the prototype';
    if (label.contains('paper')) return 'and presenting the research paper';
    return 'and presenting the idea';
  }

  static pw.Widget _participationBodyLines(CertificateData data, CertificateFonts fonts) {
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

    return pw.Column(
      children: <pw.Widget>[
        line(
          'for successfully participating in',
          CertificateSampleATheme.participationBody(fonts, size: bodySize),
        ),
        if (event.isNotEmpty)
          line(event, CertificateSampleATheme.bodyBold(fonts, size: eventNameSize), maxLines: 2),
        line(
          _presentingSubmissionPhrase(data.submissionLabel),
          CertificateSampleATheme.participationBody(fonts, size: bodySize),
        ),
        if (title.isNotEmpty)
          line(
            '"$title"',
            CertificateSampleATheme.bodySemiBold(fonts, size: ideaTitleSize),
            maxLines: 3,
          ),
        if (date.isNotEmpty)
          line(
            'held on $date',
            CertificateSampleATheme.participationBody(fonts, size: bodySize),
          ),
        line(
          'In recognition of their creativity, innovation and contribution to the event.',
          CertificateSampleATheme.participationBody(fonts, size: recognitionSize),
          maxLines: 3,
        ),
      ],
    );
  }

  static pw.Widget _certificateContent({
    required CertificateData data,
    required CertificateSampleARenderContext context,
    required CertificateVisualVariant variant,
    required CertificateFonts fonts,
    required List<CertificateSignatory> signatories,
    required bool framed,
    bool showHeaderLogos = true,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: <pw.Widget>[
        if (showHeaderLogos) ...<pw.Widget>[
          _headerRow(data, fonts),
          pw.SizedBox(height: framed ? 10 : 16),
        ],
        if (variant.showTrophy || variant.showMedal || variant.showLaurels)
          _achievementBand(context, variant),
        _headlineBlock(data, variant, fonts),
        pw.SizedBox(height: 14),
        pw.Text(
          'This certificate is proudly presented to',
          style: CertificateSampleATheme.bodyRegular(fonts),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 10),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12),
          child: pw.Text(
            data.recipientName.trim(),
            style: CertificateSampleATheme.recipientScript(
              fonts,
              CertificateSampleATheme.recipientFontSize(data.recipientName),
            ),
            textAlign: pw.TextAlign.center,
            maxLines: 3,
          ),
        ),
        if (_memberOfLine(data).isNotEmpty) ...<pw.Widget>[
          pw.SizedBox(height: 6),
          pw.Text(
            _memberOfLine(data),
            style: CertificateSampleATheme.bodyRegular(fonts, size: 10),
            textAlign: pw.TextAlign.center,
          ),
        ],
        pw.SizedBox(height: 8),
        _recipientDivider(context, variant),
        pw.SizedBox(height: 12),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8),
          child: _bodyRichText(data, fonts),
        ),
        pw.Spacer(),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: <pw.Widget>[
            pw.Expanded(child: _signatoryBlock(signatories[0], fonts)),
            pw.SizedBox(width: 24),
            pw.Expanded(child: _signatoryBlock(signatories[1], fonts)),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text(
            variant.closingLine,
            style: CertificateSampleATheme.footerTagline(fonts),
            textAlign: pw.TextAlign.center,
          ),
        ),
      ],
    );
  }

  static pw.Widget _recipientDivider(CertificateSampleARenderContext context, CertificateVisualVariant variant) {
    final pw.MemoryImage? asset =
        variant.usesGoldAccents ? context.dividerGold : context.dividerSilver;
    if (asset != null) {
      return pw.Center(
        child: pw.SizedBox(
          width: 220,
          child: pw.Image(asset, fit: pw.BoxFit.contain),
        ),
      );
    }
    return pw.Center(
      child: pw.Container(
        width: 200,
        height: 1,
        color: PdfColor.fromInt(variant.usesGoldAccents ? 0xFFC9A227 : 0xFF94A3B8),
      ),
    );
  }

  static List<pw.Widget> _cornerDecorations(
    CertificateSampleARenderContext context,
    CertificateVisualVariant variant,
  ) {
    if (context.navyCornerTopLeft == null || context.navyCornerBottomRight == null) {
      return const <pw.Widget>[];
    }
    const double corner = 118;
    final pw.MemoryImage? ribbonsTl =
        variant.usesGoldAccents ? context.goldRibbonsTopLeft : context.silverRibbonsTopLeft;
    final pw.MemoryImage? ribbonsBr =
        variant.usesGoldAccents ? context.goldRibbonsBottomRight : context.silverRibbonsBottomRight;

    return <pw.Widget>[
      pw.Positioned(
        top: 0,
        left: 0,
        child: pw.SizedBox(
          width: corner,
          height: corner,
          child: pw.Stack(
            children: <pw.Widget>[
              pw.Image(context.navyCornerTopLeft!, fit: pw.BoxFit.cover),
              if (ribbonsTl != null) pw.Image(ribbonsTl, fit: pw.BoxFit.cover),
            ],
          ),
        ),
      ),
      pw.Positioned(
        bottom: 0,
        right: 0,
        child: pw.SizedBox(
          width: corner,
          height: corner,
          child: pw.Stack(
            children: <pw.Widget>[
              pw.Image(context.navyCornerBottomRight!, fit: pw.BoxFit.cover),
              if (ribbonsBr != null) pw.Image(ribbonsBr, fit: pw.BoxFit.cover),
            ],
          ),
        ),
      ),
    ];
  }

  static pw.Widget _achievementBand(
    CertificateSampleARenderContext context,
    CertificateVisualVariant variant,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: <pw.Widget>[
          if (variant.showLaurels && _laurelImage(context, variant) != null)
            pw.SizedBox(
              width: 130,
              height: 36,
              child: pw.Image(_laurelImage(context, variant)!, fit: pw.BoxFit.contain),
            ),
          if (variant.showTrophy && context.trophyGold != null)
            pw.SizedBox(
              width: 44,
              height: 48,
              child: pw.Image(context.trophyGold!, fit: pw.BoxFit.contain),
            ),
          if (variant.showMedal && context.medalSilver != null)
            pw.SizedBox(
              width: 44,
              height: 48,
              child: pw.Image(context.medalSilver!, fit: pw.BoxFit.contain),
            ),
          if (variant.showLaurels && _laurelImage(context, variant) != null)
            pw.Transform.rotate(
              angle: 3.14159,
              child: pw.SizedBox(
                width: 130,
                height: 36,
                child: pw.Image(_laurelImage(context, variant)!, fit: pw.BoxFit.contain),
              ),
            ),
        ],
      ),
    );
  }

  static pw.MemoryImage? _laurelImage(
    CertificateSampleARenderContext context,
    CertificateVisualVariant variant,
  ) {
    return variant.usesGoldAccents ? context.laurelsGold : context.laurelsSilver;
  }

  static pw.Widget _headerRow(CertificateData data, CertificateFonts fonts) {
    final pw.ImageProvider? hackz = data.hackzLogo;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              if (hackz != null)
                pw.SizedBox(height: 52, child: pw.Image(hackz, fit: pw.BoxFit.contain))
              else
                pw.Text('HACKZ', style: CertificateSampleATheme.orgHeader(fonts)),
            ],
          ),
        ),
        CertificateOrganisationBranding.build(
          fonts: fonts,
          organisationName: data.organisationName,
          organisationLogo: data.organisationLogo,
          layout: CertificateOrganisationBrandingLayout.headerTopRight,
        ),
      ],
    );
  }

  static pw.Widget _headlineBlock(
    CertificateData data,
    CertificateVisualVariant variant,
    CertificateFonts fonts,
  ) {
    switch (data.certificateType) {
      case CertificateType.participation:
        return pw.Column(
          children: <pw.Widget>[
            pw.Text(
              'CERTIFICATE OF',
              style: CertificateSampleATheme.headingMain(fonts, size: 22),
              textAlign: pw.TextAlign.center,
            ),
            pw.Text(
              'PARTICIPATION',
              style: CertificateSampleATheme.headingMain(fonts, size: 30),
              textAlign: pw.TextAlign.center,
            ),
          ],
        );
      case CertificateType.winner:
        return pw.Column(
          children: <pw.Widget>[
            pw.Text(
              'WINNER',
              style: CertificateSampleATheme.headingMain(fonts, size: 34),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              _achievementHeadline(data, fallback: 'FIRST PLACE'),
              style: CertificateSampleATheme.achievementSubhead(variant, fonts),
              textAlign: pw.TextAlign.center,
            ),
          ],
        );
      case CertificateType.runnerUp:
        return pw.Column(
          children: <pw.Widget>[
            pw.Text(
              'RUNNER-UP',
              style: CertificateSampleATheme.headingMain(fonts, size: 32),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              _achievementHeadline(data, fallback: 'SECOND PLACE'),
              style: CertificateSampleATheme.achievementSubhead(variant, fonts),
              textAlign: pw.TextAlign.center,
            ),
          ],
        );
    }
  }

  static pw.Widget _bodyRichText(CertificateData data, CertificateFonts fonts) {
    final String event = data.eventName.trim();
    final String title = data.submissionTitle.trim();
    final String label = data.submissionLabel.trim().toLowerCase();
    final String date = data.eventDateLabel.trim();
    final String submissionPhrase = label.isEmpty ? 'submission' : label;

    final String prefix = switch (data.certificateType) {
      CertificateType.participation => 'for successfully participating in',
      CertificateType.winner => 'for outstanding innovation and exceptional performance in',
      CertificateType.runnerUp => 'for commendable innovation and excellent performance in',
    };
    final String suffix = switch (data.certificateType) {
      CertificateType.participation =>
        'In recognition of their creativity, innovation and contribution to the event.',
      CertificateType.winner => 'Your ideas inspire a better tomorrow.',
      CertificateType.runnerUp => 'Well done on turning ideas into impact.',
    };

    final String held = date.isEmpty ? '' : ' held on $date';
    final String withSubmission = title.isEmpty
        ? ''
        : ' with the $submissionPhrase $title';

    final String plain = '$prefix ${event.isEmpty ? 'the event' : event}$withSubmission$held. $suffix';
    final double size = CertificateSampleATheme.bodyFontSize(plain);

    return pw.RichText(
      textAlign: pw.TextAlign.center,
      text: pw.TextSpan(
        style: CertificateSampleATheme.bodyRegular(fonts, size: size),
        children: <pw.TextSpan>[
          pw.TextSpan(text: '$prefix '),
          if (event.isNotEmpty)
            pw.TextSpan(text: event, style: CertificateSampleATheme.bodyBold(fonts, size: size)),
          if (withSubmission.isNotEmpty) ...<pw.TextSpan>[
            pw.TextSpan(text: ' with the $submissionPhrase '),
            pw.TextSpan(
              text: title,
              style: CertificateSampleATheme.bodySemiBold(
                fonts,
                size: CertificateSampleATheme.submissionFontSize(title),
              ),
            ),
          ],
          if (held.isNotEmpty) ...<pw.TextSpan>[
            pw.TextSpan(text: ' held on '),
            pw.TextSpan(text: date, style: CertificateSampleATheme.bodyBold(fonts, size: size)),
          ],
          pw.TextSpan(text: '. $suffix'),
        ],
      ),
    );
  }

  static String _achievementHeadline(CertificateData data, {required String fallback}) {
    final String label = data.achievementLabel.trim().toUpperCase();
    if (label.isEmpty) return fallback;
    return label;
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
    return list.take(2).toList(growable: false);
  }

  static pw.Widget _signatoryBlock(
    CertificateSignatory signatory,
    CertificateFonts fonts, {
    bool compact = false,
  }) {
    final String name = signatory.name.trim();
    final String designation = signatory.designation.trim();
    final double sigHeight = compact ? 22 : 34;
    final double lineWidth = compact ? 130 : 110;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: <pw.Widget>[
        if (signatory.signatureImage != null)
          pw.SizedBox(
            height: sigHeight,
            child: pw.Image(signatory.signatureImage!, fit: pw.BoxFit.contain),
          )
        else if (!compact)
          pw.SizedBox(height: sigHeight),
        pw.Container(width: lineWidth, height: 0.6, color: CertificateSampleATheme.ink),
        pw.SizedBox(height: 5),
        if (name.isNotEmpty)
          pw.Text(
            name,
            style: CertificateSampleATheme.signatoryName(fonts),
            textAlign: pw.TextAlign.center,
            maxLines: 2,
          ),
        if (designation.isNotEmpty)
          pw.Text(
            designation,
            style: CertificateSampleATheme.signatoryTitle(fonts),
            textAlign: pw.TextAlign.center,
            maxLines: 2,
          ),
      ],
    );
  }
}
