/// Achievement tier for certificate styling (participation, winner, runner-up).
enum CertificateType {
  participation,
  winner,
  runnerUp,
  thirdPlace,
}

enum CertificateRecipientType {
  team,
  individual,
}

extension CertificateTypeCodec on CertificateType {
  String get wireValue => switch (this) {
        CertificateType.participation => 'participation',
        CertificateType.winner => 'winner',
        CertificateType.runnerUp => 'runner_up',
        CertificateType.thirdPlace => 'third_place',
      };

  static CertificateType? parse(String? raw) {
    final String value = (raw ?? '').trim().toLowerCase();
    return switch (value) {
      'participation' => CertificateType.participation,
      'winner' => CertificateType.winner,
      'runner_up' || 'runner-up' || 'runnerup' => CertificateType.runnerUp,
      'third_place' || 'third-place' || 'thirdplace' => CertificateType.thirdPlace,
      _ => null,
    };
  }
}

extension CertificateRecipientTypeCodec on CertificateRecipientType {
  String get wireValue => switch (this) {
        CertificateRecipientType.team => 'team',
        CertificateRecipientType.individual => 'individual',
      };

  static CertificateRecipientType parse(String? raw) {
    final String value = (raw ?? '').trim().toLowerCase();
    return value == 'individual'
        ? CertificateRecipientType.individual
        : CertificateRecipientType.team;
  }
}
