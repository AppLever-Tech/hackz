import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import 'certificate_type.dart';

/// Normalized payload for the certificate renderer.
class CertificateSignatory {
  const CertificateSignatory({
    this.name = '',
    this.designation = '',
    this.signatureImage,
  });

  final String name;
  final String designation;

  /// Optional decoded signature image (PNG/JPEG bytes).
  final pw.ImageProvider? signatureImage;
}

class CertificateData {
  const CertificateData({
    required this.certificateType,
    required this.recipientType,
    required this.recipientName,
    required this.organisationName,
    required this.eventName,
    required this.eventTemplateLabel,
    required this.eventDateLabel,
    required this.submissionTitle,
    required this.submissionLabel,
    this.teamName = '',
    this.achievementLabel = '',
    this.organisationLogo,
    this.hackzLogo,
    this.signatories = const <CertificateSignatory>[],
  });

  final CertificateType certificateType;
  final CertificateRecipientType recipientType;
  final String recipientName;
  final String teamName;
  final String organisationName;
  final pw.ImageProvider? organisationLogo;
  final pw.ImageProvider? hackzLogo;
  final String eventName;
  final String eventTemplateLabel;
  final String eventDateLabel;
  final String submissionTitle;
  final String submissionLabel;
  final String achievementLabel;
  final List<CertificateSignatory> signatories;

  /// Optional raw logo bytes for callers that resolve assets outside the renderer.
  static pw.MemoryImage? memoryImageFromBytes(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return null;
    return pw.MemoryImage(bytes);
  }
}
