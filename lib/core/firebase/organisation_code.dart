import 'dart:math';

/// Human-facing Hackz organisation routing code: `HKZ-XXXXXX`.
///
/// Generated automatically and stable once assigned. Login uses this code to
/// resolve the tenant Firebase project. Case-insensitive; callers must
/// [normalize] input.
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

  /// Formats typed or pasted input toward `HKZ-XXXXXX` without requiring a valid code yet.
  static String formatInput(String input) {
    final String compact = normalize(input).replaceAll(RegExp(r'[^A-Z0-9-]'), '');
    if (compact.isEmpty) return '';

    final String letters = compact.replaceAll('-', '');
    if (letters.startsWith('HKZ')) {
      final String body = letters.length > 3 ? letters.substring(3) : '';
      final String clipped =
          body.length > bodyLength ? body.substring(0, bodyLength) : body;
      if (clipped.isEmpty) return 'HKZ';
      return '$prefix$clipped';
    }
    if ('HKZ'.startsWith(letters) && letters.length <= 3) {
      return letters;
    }
    return compact.length > (prefix.length + bodyLength)
        ? compact.substring(0, prefix.length + bodyLength)
        : compact;
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
