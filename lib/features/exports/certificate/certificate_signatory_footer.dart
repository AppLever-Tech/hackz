import 'package:pdf/widgets.dart' as pw;

import 'certificate_data.dart';
import 'certificate_fonts.dart';
import 'certificate_theme.dart';

/// Signatory block at the bottom of every certificate type (shared layout).
abstract final class CertificateSignatoryFooter {
  CertificateSignatoryFooter._();

  static const double gapFromCenter = 12;
  static const double sideWidth = 132;
  static const double centerWidth = 128;
  static const double signatureImageWidth = 120;
  static const double signatureImageHeight = 36;

  static pw.Widget build(List<CertificateSignatory> signatories, CertificateFonts fonts) {
    if (signatories.length >= 3 && _hasContent(signatories[2])) {
      return _threeSignatoryLayout(signatories, fonts);
    }
    return _twoSignatoryLayout(signatories, fonts);
  }

  static pw.Widget _signatureLineBlock({
    required pw.ImageProvider? signatureImage,
    required double lineWidth,
  }) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: <pw.Widget>[
        if (signatureImage != null)
          pw.SizedBox(
            width: signatureImageWidth,
            height: signatureImageHeight,
            child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
          ),
        pw.Container(width: lineWidth, height: 0.6, color: CertificateTheme.ink),
      ],
    );
  }

  static pw.Widget _twoSignatoryLayout(List<CertificateSignatory> signatories, CertificateFonts fonts) {
    final CertificateSignatory left = signatories[0];
    final CertificateSignatory right = signatories[1];
    const double lineWidth = sideWidth;

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

    pw.Widget centeredText(String text, pw.TextStyle style, {int maxLines = 2}) {
      return pw.Text(
        text,
        style: style,
        textAlign: pw.TextAlign.center,
        maxLines: maxLines,
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
            width: sideWidth,
            child: pw.Align(alignment: pw.Alignment.topCenter, child: left),
          ),
          pw.SizedBox(width: gapFromCenter),
          pw.SizedBox(
            width: centerWidth,
            child: pw.Align(alignment: pw.Alignment.topCenter, child: center),
          ),
          pw.SizedBox(width: gapFromCenter),
          pw.SizedBox(
            width: sideWidth,
            child: pw.Align(alignment: pw.Alignment.topCenter, child: right),
          ),
        ],
      );
    }

    return pw.Column(
      children: <pw.Widget>[
        footerRow(
          left: _signatureLineBlock(signatureImage: left.signatureImage, lineWidth: lineWidth),
          center: pw.SizedBox(),
          right: _signatureLineBlock(signatureImage: right.signatureImage, lineWidth: lineWidth),
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

  static pw.Widget _threeSignatoryLayout(List<CertificateSignatory> signatories, CertificateFonts fonts) {
    final CertificateSignatory left = signatories[0];
    final CertificateSignatory right = signatories[1];
    final CertificateSignatory center = signatories[2];
    const double lineWidth = sideWidth;

    pw.Widget slot(CertificateSignatory signatory) {
      return pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: <pw.Widget>[
          _signatureLineBlock(signatureImage: signatory.signatureImage, lineWidth: lineWidth),
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
        pw.SizedBox(width: sideWidth, child: slot(left)),
        pw.SizedBox(width: gapFromCenter),
        pw.SizedBox(width: centerWidth, child: slot(center)),
        pw.SizedBox(width: gapFromCenter),
        pw.SizedBox(width: sideWidth, child: slot(right)),
      ],
    );
  }

  static bool _hasContent(CertificateSignatory signatory) {
    return signatory.name.trim().isNotEmpty ||
        signatory.designation.trim().isNotEmpty ||
        signatory.signatureImage != null;
  }
}
