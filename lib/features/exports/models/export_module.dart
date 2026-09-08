/// PDF layout family. Excel ignores this; the PDF engine picks a template.
enum ExportDocumentKind { report, certificate }

/// Logical export kind. Providers choose one; renderers stay format-specific.
enum ExportModule {
  problemStatements,
  ideas,
  payments,
  evaluationResults,
  participationCertificate,
  winnerCertificate;

  String get fileToken => switch (this) {
    ExportModule.problemStatements => 'ProblemStatements',
    ExportModule.ideas => 'Ideas',
    ExportModule.payments => 'Payments',
    ExportModule.evaluationResults => 'EvaluationResults',
    ExportModule.participationCertificate => 'ParticipationCertificate',
    ExportModule.winnerCertificate => 'WinnerCertificate',
  };

  String get displayName => switch (this) {
    ExportModule.problemStatements => 'Problem Statements',
    ExportModule.ideas => 'Ideas',
    ExportModule.payments => 'Payments',
    ExportModule.evaluationResults => 'Evaluation Results',
    ExportModule.participationCertificate => 'Participation Certificate',
    ExportModule.winnerCertificate => 'Winner Certificate',
  };

  ExportDocumentKind get documentKind => switch (this) {
    ExportModule.participationCertificate ||
    ExportModule.winnerCertificate => ExportDocumentKind.certificate,
    _ => ExportDocumentKind.report,
  };
}
