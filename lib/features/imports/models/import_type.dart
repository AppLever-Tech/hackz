/// Supported CSV import targets. Extend this enum for future import types.
enum ImportType {
  users('Users'),
  problems('Problems'),
  teamRegistration('Team Registration');

  const ImportType(this.label);
  final String label;
}
