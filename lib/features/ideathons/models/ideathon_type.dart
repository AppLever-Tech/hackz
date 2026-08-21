/// Whether an Ideathon is limited to the host organisation or open more broadly.
enum IdeathonType {
  internal('INTERNAL', 'Internal'),
  external('EXTERNAL', 'External');

  const IdeathonType(this.value, this.label);

  final String value;
  final String label;

  String get helpText => switch (this) {
        IdeathonType.internal => 'Teams from the host organisation.',
        IdeathonType.external =>
          'Teams from the host or other organisations, including mixed teams.',
      };

  static IdeathonType fromRaw(String? raw) {
    final String v = (raw ?? '').trim().toUpperCase();
    if (v == IdeathonType.external.value || v == IdeathonType.external.label.toUpperCase()) {
      return IdeathonType.external;
    }
    return IdeathonType.internal;
  }
}
