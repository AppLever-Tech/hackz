import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'certificate_data.dart';
import 'certificate_fonts.dart';
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
          _participationHeaderLogos(data, fonts),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(40, 104, 40, 28),
            child: _certificateContent(
              data: data,
              context: context,
              variant: variant,
              fonts: fonts,
              signatories: signatories,
              framed: false,
              showHeaderLogos: false,
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

  /// Hackz logo sits just to the right of the baked-in top-left corner (Sample A).
  static const double _participationHackzLogoTop = 30;
  static const double _participationHackzLogoLeft = 120;
  static const double _participationHackzLogoHeight = 76;
  static const double _participationOrgLogoTop = 24;
  static const double _participationOrgLogoRight = 34;

  static pw.Widget _participationHeaderLogos(CertificateData data, CertificateFonts fonts) {
    final pw.ImageProvider? hackz = data.hackzLogo;
    final pw.ImageProvider? org = data.organisationLogo;
    final String orgName = data.organisationName.trim();

    return pw.Stack(
      children: <pw.Widget>[
        if (hackz != null)
          pw.Positioned(
            top: _participationHackzLogoTop,
            left: _participationHackzLogoLeft,
            child: pw.SizedBox(
              height: _participationHackzLogoHeight,
              width: 168,
              child: pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Image(hackz, fit: pw.BoxFit.contain),
              ),
            ),
          )
        else
          pw.Positioned(
            top: _participationHackzLogoTop + 24,
            left: _participationHackzLogoLeft,
            child: pw.Text('HACKZ', style: CertificateSampleATheme.orgHeader(fonts)),
          ),
        if (org != null)
          pw.Positioned(
            top: _participationOrgLogoTop,
            right: _participationOrgLogoRight,
            child: pw.SizedBox(
              height: 58,
              width: 200,
              child: pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Image(org, fit: pw.BoxFit.contain),
              ),
            ),
          )
        else if (orgName.isNotEmpty)
          pw.Positioned(
            top: _participationOrgLogoTop,
            right: _participationOrgLogoRight,
            left: _participationHackzLogoLeft + 180,
            child: pw.Text(
              orgName,
              style: CertificateSampleATheme.orgHeader(fonts),
              textAlign: pw.TextAlign.right,
              maxLines: 3,
            ),
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
    final pw.ImageProvider? org = data.organisationLogo;
    final String orgName = data.organisationName.trim();

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
        if (org != null)
          pw.SizedBox(
            width: 200,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: <pw.Widget>[
                pw.SizedBox(
                  height: 46,
                  child: pw.Align(
                    alignment: pw.Alignment.centerRight,
                    child: pw.Image(org, fit: pw.BoxFit.contain),
                  ),
                ),
              ],
            ),
          )
        else if (orgName.isNotEmpty)
          pw.Expanded(
            child: pw.Text(
              orgName,
              style: CertificateSampleATheme.orgHeader(fonts),
              textAlign: pw.TextAlign.right,
              maxLines: 3,
            ),
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

  static pw.Widget _signatoryBlock(CertificateSignatory signatory, CertificateFonts fonts) {
    final String name = signatory.name.trim();
    final String designation = signatory.designation.trim();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: <pw.Widget>[
        if (signatory.signatureImage != null)
          pw.SizedBox(
            height: 34,
            child: pw.Image(signatory.signatureImage!, fit: pw.BoxFit.contain),
          )
        else
          pw.SizedBox(height: 34),
        pw.Container(width: 110, height: 0.6, color: CertificateSampleATheme.ink),
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
