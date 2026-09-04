import 'dart:math';

/// Human-facing Hackz organisation routing code: `HKZ-XXXXXX`.
///
/// Generated automatically. Colleges never enter or choose this value.
/// Stable once assigned. Case-insensitive; callers must [normalize] input.
abstract final class OrganisationCode {
  OrganisationCode._();

  static const String prefix = 'HKZ-';
  static const int bodyLength = 6;

  /// Ambiguous `0/O` and `1/I` are omitted so codes stay easy to type.
  static const String alphabet = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  static final RegExp _valid = RegExp('^$prefix[$alphabet]{$bodyLength}\$');

  /// Trim, drop internal whitespace, and uppercase.
  static String normalize(String input) {
    return input.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
  }

  static bool isValid(String input) => _valid.hasMatch(normalize(input));

  /// Normalized code, or `null` when the value is not a Hackz organisation code.
  static String? tryParse(String input) {
    final String normalized = normalize(input);
    if (!_valid.hasMatch(normalized)) return null;
    return normalized;
  }

  /// Random `HKZ-XXXXXX`. Not derived from the organisation name.
  static String generate({Random? random}) {
    final Random rng = random ?? Random.secure();
    final StringBuffer body = StringBuffer();
    for (int i = 0; i < bodyLength; i++) {
      body.write(alphabet[rng.nextInt(alphabet.length)]);
    }
    return '$prefix$body';
  }
}
