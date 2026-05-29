/// Industry-facing judge classification stored on [JudgeProfile].
enum JudgeType {
  internal('Internal'),
  external('External'),
  industry('Industry'),
  academic('Academic');

  const JudgeType(this.label);
  final String label;

  static JudgeType? fromRaw(String? raw) {
    final String value = (raw ?? '').trim();
    if (value.isEmpty) return null;
    for (final JudgeType type in JudgeType.values) {
      if (type.name == value.toLowerCase() || type.label == value) {
        return type;
      }
    }
    return null;
  }

  String get storageValue => label;
}
