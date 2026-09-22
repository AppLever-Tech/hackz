import 'package:pdf/widgets.dart' as pw;

import 'certificate_data.dart';
import 'certificate_sample_a_theme.dart';
import 'certificate_type.dart';

/// Single data-driven Sample A certificate page builder (A1 / A2 / A3).
abstract final class CertificateSampleARenderer {
  CertificateSampleARenderer._();

  static pw.Widget buildPage(CertificateData data) {
    final CertificatePalette palette = CertificateSampleATheme.palette(data.certificateType);
    final List<CertificateSignatory> signatories = _normalizedSignatories(data.signatories);

    return pw.Stack(
      children: <pw.Widget>[
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: palette.accent, width: 2),
            color: CertificateSampleATheme.white,
          ),
          padding: const pw.EdgeInsets.all(10),
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: CertificateSampleATheme.line, width: 0.8),
            ),
            padding: const pw.EdgeInsets.fromLTRB(32, 24, 32, 22),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: <pw.Widget>[
                _logoRow(data),
                pw.SizedBox(height: 18),
                _headlineBlock(data, palette),
                pw.SizedBox(height: 8),
                pw.Text(
                  data.organisationName.trim(),
                  style: CertificateSampleATheme.orgName,
                  textAlign: pw.TextAlign.center,
                  maxLines: 2,
                ),
                pw.SizedBox(height: 22),
                pw.Container(height: 0.8, color: CertificateSampleATheme.line),
                pw.SizedBox(height: 20),
                pw.Text(
                  'This is to certify that',
                  style: CertificateSampleATheme.body,
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 14),
                pw.Text(
                  data.recipientName.trim(),
                  style: CertificateSampleATheme.recipient,
                  textAlign: pw.TextAlign.center,
                  maxLines: 3,
                ),
                if (_memberOfLine(data).isNotEmpty) ...<pw.Widget>[
                  pw.SizedBox(height: 8),
                  pw.Text(
                    _memberOfLine(data),
                    style: CertificateSampleATheme.body,
                    textAlign: pw.TextAlign.center,
                  ),
                ],
                pw.SizedBox(height: 16),
                pw.Text(
                  _achievementSentence(data),
                  style: CertificateSampleATheme.body,
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 12),
                if (data.eventName.trim().isNotEmpty)
                  pw.Text(
                    data.eventName.trim(),
                    style: CertificateSampleATheme.eventTitle,
                    textAlign: pw.TextAlign.center,
                    maxLines: 2,
                  ),
                if (_eventMeta(data).isNotEmpty) ...<pw.Widget>[
                  pw.SizedBox(height: 6),
                  pw.Text(
                    _eventMeta(data),
                    style: CertificateSampleATheme.body,
                    textAlign: pw.TextAlign.center,
                  ),
                ],
                if (_submissionLine(data).isNotEmpty) ...<pw.Widget>[
                  pw.SizedBox(height: 10),
                  pw.Text(
                    _submissionLine(data),
                    style: CertificateSampleATheme.submission,
                    textAlign: pw.TextAlign.center,
                    maxLines: 3,
                  ),
                ],
                pw.Spacer(),
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: <pw.Widget>[
                    pw.Expanded(child: _signatoryBlock(signatories[0])),
                    pw.SizedBox(width: 40),
                    pw.Expanded(child: _signatoryBlock(signatories[1])),
                  ],
                ),
                pw.SizedBox(height: 14),
                pw.Align(
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    'Powered by Hackz',
                    style: CertificateSampleATheme.footerBrand,
                  ),
                ),
              ],
            ),
          ),
        ),
        ..._cornerAccents(palette),
      ],
    );
  }

  static List<pw.Widget> _cornerAccents(CertificatePalette palette) {
    const double size = 28;
    const double stroke = 2.2;
    pw.Widget corner(pw.Alignment alignment) {
      return pw.Align(
        alignment: alignment,
        child: pw.Container(
          width: size,
          height: size,
          margin: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: palette.accent, width: stroke),
              left: pw.BorderSide(color: palette.accent, width: stroke),
            ),
          ),
        ),
      );
    }

    return <pw.Widget>[
      corner(pw.Alignment.topLeft),
      pw.Align(
        alignment: pw.Alignment.topRight,
        child: pw.Container(
          width: size,
          height: size,
          margin: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: palette.accent, width: stroke),
              right: pw.BorderSide(color: palette.accent, width: stroke),
            ),
          ),
        ),
      ),
      pw.Align(
        alignment: pw.Alignment.bottomLeft,
        child: pw.Container(
          width: size,
          height: size,
          margin: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: palette.accent, width: stroke),
              left: pw.BorderSide(color: palette.accent, width: stroke),
            ),
          ),
        ),
      ),
      pw.Align(
        alignment: pw.Alignment.bottomRight,
        child: pw.Container(
          width: size,
          height: size,
          margin: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: palette.accent, width: stroke),
              right: pw.BorderSide(color: palette.accent, width: stroke),
            ),
          ),
        ),
      ),
    ];
  }

  static pw.Widget _logoRow(CertificateData data) {
    final pw.ImageProvider? hackz = data.hackzLogo;
    final pw.ImageProvider? org = data.organisationLogo;
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: <pw.Widget>[
        _logoSlot(hackz, fallback: 'HACKZ'),
        pw.Spacer(),
        if (org != null)
          _logoImage(org, height: 42)
        else if (data.organisationName.trim().isNotEmpty)
          pw.Expanded(
            child: pw.Text(
              data.organisationName.trim(),
              style: CertificateSampleATheme.orgName,
              textAlign: pw.TextAlign.right,
              maxLines: 2,
            ),
          )
        else
          pw.SizedBox(width: 48),
      ],
    );
  }

  static pw.Widget _logoSlot(pw.ImageProvider? image, {required String fallback}) {
    if (image != null) {
      return _logoImage(image, height: 36);
    }
    return pw.Text(
      fallback,
      style: pw.TextStyle(
        font: pw.Font.helveticaBold(),
        fontSize: 13,
        letterSpacing: 1.6,
        color: CertificateSampleATheme.navy,
      ),
    );
  }

  static pw.Widget _logoImage(pw.ImageProvider image, {required double height}) {
    return pw.SizedBox(
      height: height,
      child: pw.Image(image, fit: pw.BoxFit.contain),
    );
  }

  static pw.Widget _headlineBlock(CertificateData data, CertificatePalette palette) {
    switch (data.certificateType) {
      case CertificateType.participation:
        return pw.Column(
          children: <pw.Widget>[
            pw.Text(
              'CERTIFICATE OF',
              style: CertificateSampleATheme.headlinePrimary(palette),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'PARTICIPATION',
              style: CertificateSampleATheme.headlineSecondary(palette),
              textAlign: pw.TextAlign.center,
            ),
          ],
        );
      case CertificateType.winner:
        return pw.Column(
          children: <pw.Widget>[
            pw.Text(
              'WINNER',
              style: CertificateSampleATheme.headlinePrimary(palette),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              _achievementHeadline(data, fallback: 'FIRST PLACE'),
              style: CertificateSampleATheme.headlineSecondary(palette),
              textAlign: pw.TextAlign.center,
            ),
          ],
        );
      case CertificateType.runnerUp:
        return pw.Column(
          children: <pw.Widget>[
            pw.Text(
              'RUNNER-UP',
              style: CertificateSampleATheme.headlinePrimary(palette),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              _achievementHeadline(data, fallback: 'SECOND PLACE'),
              style: CertificateSampleATheme.headlineSecondary(palette),
              textAlign: pw.TextAlign.center,
            ),
          ],
        );
    }
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

  static String _achievementSentence(CertificateData data) {
    final String submission = data.submissionLabel.trim();
    final String submissionPhrase =
        submission.isEmpty ? 'the submission' : 'the $submission';
    return switch (data.certificateType) {
      CertificateType.participation =>
        'has successfully participated in the following event with $submissionPhrase',
      CertificateType.winner =>
        'is recognized as the winner for $submissionPhrase in the following event',
      CertificateType.runnerUp =>
        'is recognized as the runner-up for $submissionPhrase in the following event',
    };
  }

  static String _eventMeta(CertificateData data) {
    return <String>[
      data.eventTemplateLabel.trim(),
      data.eventDateLabel.trim(),
    ].where((String part) => part.isNotEmpty).join('  ·  ');
  }

  static String _submissionLine(CertificateData data) {
    final String title = data.submissionTitle.trim();
    final String label = data.submissionLabel.trim();
    if (title.isEmpty) return '';
    if (label.isEmpty) return title;
    return '$label: $title';
  }

  static List<CertificateSignatory> _normalizedSignatories(List<CertificateSignatory> input) {
    final List<CertificateSignatory> list = List<CertificateSignatory>.from(input);
    while (list.length < 2) {
      list.add(const CertificateSignatory());
    }
    return list.take(2).toList(growable: false);
  }

  static pw.Widget _signatoryBlock(CertificateSignatory signatory) {
    final String name = signatory.name.trim();
    final String designation = signatory.designation.trim();
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: <pw.Widget>[
        if (signatory.signatureImage != null)
          pw.SizedBox(
            height: 36,
            child: pw.Image(signatory.signatureImage!, fit: pw.BoxFit.contain),
          )
        else
          pw.SizedBox(height: 36),
        pw.Container(width: 120, height: 0.8, color: CertificateSampleATheme.ink),
        pw.SizedBox(height: 6),
        if (name.isNotEmpty)
          pw.Text(name, style: CertificateSampleATheme.signatoryName, textAlign: pw.TextAlign.center),
        if (designation.isNotEmpty)
          pw.Text(
            designation,
            style: CertificateSampleATheme.signatoryTitle,
            textAlign: pw.TextAlign.center,
            maxLines: 2,
          ),
      ],
    );
  }
}
