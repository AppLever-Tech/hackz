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
}
