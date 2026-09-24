import 'package:pdf/widgets.dart' as pw;

import 'certificate_fonts.dart';
import 'certificate_theme.dart';

/// Layout tokens for the college branding region on certificates.
class CertificateOrganisationBrandingLayout {
  const CertificateOrganisationBrandingLayout._({
    required this.maxWidth,
    required this.alignment,
    required this.logoMaxHeight,
    required this.logoMaxWidth,
    required this.nameWithLogoBaseSize,
    required this.nameOnlyBaseSize,
    required this.nameWithLogoMinSize,
    required this.nameOnlyMinSize,
  });

  final double maxWidth;
  final pw.Alignment alignment;
  final double logoMaxHeight;
  final double logoMaxWidth;
  final double nameWithLogoBaseSize;
  final double nameOnlyBaseSize;
  final double nameWithLogoMinSize;
  final double nameOnlyMinSize;

  static const CertificateOrganisationBrandingLayout participationTopRight =
      CertificateOrganisationBrandingLayout._(
    maxWidth: 200,
    alignment: pw.Alignment.centerRight,
    logoMaxHeight: 44,
    logoMaxWidth: 54,
    nameWithLogoBaseSize: 12.5,
    nameOnlyBaseSize: 16.5,
    nameWithLogoMinSize: 9.5,
    nameOnlyMinSize: 11.5,
  );

  static const CertificateOrganisationBrandingLayout headerTopRight =
      CertificateOrganisationBrandingLayout._(
    maxWidth: 220,
    alignment: pw.Alignment.centerRight,
    logoMaxHeight: 42,
    logoMaxWidth: 52,
    nameWithLogoBaseSize: 12,
    nameOnlyBaseSize: 15.5,
    nameWithLogoMinSize: 9.5,
    nameOnlyMinSize: 11,
  );
}

/// College / organisation branding (logo + name or name-only).
abstract final class CertificateOrganisationBranding {
  CertificateOrganisationBranding._();

  static const double _logoNameGap = 8;
  static const int _maxNameLines = 3;

  static pw.Widget build({
    required CertificateFonts fonts,
    required String organisationName,
    pw.ImageProvider? organisationLogo,
    required CertificateOrganisationBrandingLayout layout,
  }) {
    final String name = organisationName.trim();
    if (name.isEmpty && organisationLogo == null) {
      return pw.SizedBox();
    }

    final pw.Widget branding = organisationLogo != null
        ? _logoAndName(
            fonts: fonts,
            name: name,
            logo: organisationLogo,
            layout: layout,
          )
        : _nameOnly(fonts: fonts, name: name, layout: layout);

    return pw.SizedBox(
      width: layout.maxWidth,
      child: pw.Align(alignment: layout.alignment, child: branding),
    );
  }

  static double fontSizeForName(String name, CertificateOrganisationBrandingLayout layout, {required bool withLogo}) {
    final int len = name.trim().length;
    final double base = withLogo ? layout.nameWithLogoBaseSize : layout.nameOnlyBaseSize;
    final double min = withLogo ? layout.nameWithLogoMinSize : layout.nameOnlyMinSize;
    double size = base;
    if (len > 22) size -= 0.5;
    if (len > 36) size -= 1;
    if (len > 52) size -= 1;
    if (len > 68) size -= 0.5;
    if (len > 84) size -= 0.5;
    if (size < min) size = min;
    return size;
  }

  static pw.Widget _logoAndName({
    required CertificateFonts fonts,
    required String name,
    required pw.ImageProvider logo,
    required CertificateOrganisationBrandingLayout layout,
  }) {
    final double nameSize = fontSizeForName(name, layout, withLogo: true);
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: <pw.Widget>[
        pw.SizedBox(
          height: layout.logoMaxHeight,
          width: layout.logoMaxWidth,
          child: pw.Image(logo, fit: pw.BoxFit.contain),
        ),
        if (name.isNotEmpty) ...<pw.Widget>[
          pw.SizedBox(width: _logoNameGap),
          pw.ConstrainedBox(
            constraints: pw.BoxConstraints(maxWidth: layout.maxWidth - layout.logoMaxWidth - _logoNameGap),
            child: pw.Text(
              name,
              style: CertificateTheme.collegeName(fonts, size: nameSize),
              textAlign: pw.TextAlign.left,
              maxLines: _maxNameLines,
              softWrap: true,
            ),
          ),
        ],
      ],
    );
  }

  static pw.Widget _nameOnly({
    required CertificateFonts fonts,
    required String name,
    required CertificateOrganisationBrandingLayout layout,
  }) {
    if (name.isEmpty) return pw.SizedBox();
    final double nameSize = fontSizeForName(name, layout, withLogo: false);
    return pw.Text(
      name,
      style: CertificateTheme.collegeName(fonts, size: nameSize),
      textAlign: pw.TextAlign.right,
      maxLines: _maxNameLines,
      softWrap: true,
    );
  }
}
