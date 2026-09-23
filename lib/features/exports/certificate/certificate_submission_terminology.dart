/// Event submission wording for certificate body copy (from [CertificateData.submissionLabel]).
abstract final class CertificateSubmissionTerminology {
  CertificateSubmissionTerminology._();

  /// Participation layout: "and presenting the …"
  static String presentingPhrase(String submissionLabel) {
    final String label = submissionLabel.trim().toLowerCase();
    if (label.contains('prototype')) return 'and presenting the prototype';
    if (label.contains('paper')) return 'and presenting the research paper';
    return 'and presenting the idea';
  }

  /// Winner / runner-up layout: "for the …"
  static String forThePhrase(String submissionLabel) {
    final String label = submissionLabel.trim().toLowerCase();
    if (label.contains('prototype')) return 'for the prototype';
    if (label.contains('paper')) return 'for the research paper';
    return 'for the idea';
  }
}
