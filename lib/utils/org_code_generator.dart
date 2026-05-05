import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/enums/organization_type.dart';
import 'firestore_utils.dart';

const Set<String> _orgStopWords = <String>{
  'INSTITUTE',
  'OF',
  'TECHNOLOGY',
  'COLLEGE',
  'ENGINEERING',
  'UNIVERSITY',
  'COMPANY',
  'PRIVATE',
  'LIMITED',
  'PVT',
  'LTD',
  'RESEARCH',
  'CENTER',
  'CENTRE',
  'TRAINING',
};

Future<String> generateOrganizationCodeFromName(
  String organizationName,
  OrganizationType organizationType,
) async {
  final normalized = _normalizeOrganizationName(organizationName);
  if (normalized.isEmpty) {
    return _typeFallback(organizationType);
  }

  final base = _buildBaseCode(normalized);
  final seeded = _enforceCodeLength(base, normalized);
  return _resolveUniqueOrganizationCode(seeded);
}

String _normalizeOrganizationName(String name) {
  final upper = name.toUpperCase().trim();
  if (upper.isEmpty) return '';
  final cleaned = upper.replaceAll(RegExp(r'[^A-Z0-9 ]+'), ' ');
  final words = cleaned
      .split(RegExp(r'\s+'))
      .map((w) => w.trim())
      .where((w) => w.isNotEmpty && !_orgStopWords.contains(w))
      .toList();
  return words.join(' ');
}

String _buildBaseCode(String normalizedName) {
  final words = normalizedName.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  if (words.isEmpty) return '';
  if (words.length == 1) {
    final word = words.first;
    return word.substring(0, word.length >= 4 ? 4 : word.length);
  }
  return words.map((w) => w[0]).join();
}

String _enforceCodeLength(String candidate, String normalizedName) {
  var code = candidate.replaceAll(RegExp(r'[^A-Z0-9]'), '');
  final letters = normalizedName.replaceAll(' ', '');
  var cursor = 0;
  while (code.length < 3 && cursor < letters.length) {
    code += letters[cursor];
    cursor++;
  }
  if (code.length < 3) {
    code = code.padRight(3, 'X');
  }
  if (code.length > 5) {
    code = code.substring(0, 5);
  }
  return code;
}

Future<String> _resolveUniqueOrganizationCode(String seed) async {
  final db = FirebaseFirestore.instance;
  final base = seed.toUpperCase();
  var code = base;
  var suffix = 1;
  while (true) {
    final snap = await db
        .collection(FirestoreUtils.hkzOrganizations)
        .where('code', isEqualTo: code)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return code;
    final suffixString = suffix.toString();
    final maxBaseLength = (5 - suffixString.length).clamp(1, 5);
    final truncatedBase = base.length > maxBaseLength ? base.substring(0, maxBaseLength) : base;
    code = '$truncatedBase$suffixString';
    suffix++;
  }
}

String _typeFallback(OrganizationType type) {
  return switch (type) {
    OrganizationType.college => 'COL',
    OrganizationType.company => 'COM',
    OrganizationType.researchInstitute => 'RES',
    OrganizationType.trainingCenter => 'TRN',
  };
}
