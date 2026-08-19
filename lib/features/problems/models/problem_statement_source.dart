/// Origin of a problem statement: authored inside the organisation or supplied externally.
enum ProblemStatementSource {
  internal('INTERNAL', 'Internal'),
  external('EXTERNAL', 'External');

  const ProblemStatementSource(this.value, this.label);

  final String value;
  final String label;

  static ProblemStatementSource? fromRaw(String? raw) {
    final String v = (raw ?? '').trim().toUpperCase();
    if (v.isEmpty) return null;
    for (final ProblemStatementSource source in values) {
      if (source.value == v || source.label.toUpperCase() == v) return source;
    }
    return null;
  }
}
