import '../models/enums/organization_type.dart';
import '../models/user_model.dart';

/// Normalize phone for Firestore lookups (E.164 style).
String normalizePhoneE164(String raw) {
  final s = raw.replaceAll(RegExp(r'\s+'), '').trim();
  if (s.startsWith('+')) return s;
  return '+91$s';
}

/// Validates a local Indian phone input (without country code).
bool isValidPhoneInput(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  return digits.length == 10;
}

/// Basic email format validation.
bool isValidEmailInput(String raw) {
  final email = raw.trim();
  if (email.isEmpty) return false;
  final pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  return pattern.hasMatch(email);
}

String generateOrganizationCode(OrganizationType type) {
  final String prefix = switch (type) {
    OrganizationType.college => 'COL',
    OrganizationType.company => 'COM',
    OrganizationType.researchInstitute => 'RES',
    OrganizationType.trainingCenter => 'TRN',
  };
  final int stamp = DateTime.now().millisecondsSinceEpoch % 100000;
  return '$prefix$stamp';
}

String userDisplayName(UserModel user) {
  final fullName = '${user.firstName} ${user.lastName}'.trim();
  return fullName.isEmpty ? user.userId : fullName;
}

List<UserModel> sortUsersByDisplayName(Iterable<UserModel> users) {
  final sorted = users.toList(growable: false);
  sorted.sort((a, b) {
    final aName = userDisplayName(a).toLowerCase();
    final bName = userDisplayName(b).toLowerCase();
    final byName = aName.compareTo(bName);
    if (byName != 0) return byName;
    return a.userId.toLowerCase().compareTo(b.userId.toLowerCase());
  });
  return sorted;
}

List<String> sortUserIdsByDisplayName(Iterable<String> userIds, Map<String, String> namesById) {
  final sorted = userIds.toList(growable: false);
  sorted.sort((a, b) {
    final aName = (namesById[a] ?? a).toLowerCase();
    final bName = (namesById[b] ?? b).toLowerCase();
    final byName = aName.compareTo(bName);
    if (byName != 0) return byName;
    return a.toLowerCase().compareTo(b.toLowerCase());
  });
  return sorted;
}

/// Full English month names indexed `month - 1`, shared by the long-form and
/// day-month-year display helpers below.
const List<String> kMonthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// Long form: "Monday, January 5, 2026" (app shell / headers).
String formatLongDisplayDate(DateTime date) {
  const weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return '${weekdays[date.weekday - 1]}, ${kMonthNames[date.month - 1]} ${date.day}, ${date.year}';
}

/// Day-month-year format: "30 June 2026" — used for human-friendly deadlines
/// and similar single-line dates where the time component would be noise.
String formatDayMonthYear(DateTime date) {
  return '${date.day} ${kMonthNames[date.month - 1]} ${date.year}';
}

/// Standard dashboard date-time format: dd/mm/yyyy hh:mm
String formatDateTime(DateTime date) {
  final dd = date.day.toString().padLeft(2, '0');
  final mm = date.month.toString().padLeft(2, '0');
  final yyyy = date.year.toString();
  final hh = date.hour.toString().padLeft(2, '0');
  final min = date.minute.toString().padLeft(2, '0');
  return '$dd/$mm/$yyyy $hh:$min';
}
