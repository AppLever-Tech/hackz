import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

/// Event-scoped certificate signatory draft (not user profile data).
class CertificateEventSignatoryDraft {
  const CertificateEventSignatoryDraft({
    this.signatoryCount = 2,
    this.slots = const <CertificateSignatorySlotDraft>[],
  });

  final int signatoryCount;
  final List<CertificateSignatorySlotDraft> slots;

  CertificateEventSignatoryDraft copyWith({
    int? signatoryCount,
    List<CertificateSignatorySlotDraft>? slots,
  }) {
    return CertificateEventSignatoryDraft(
      signatoryCount: signatoryCount ?? this.signatoryCount,
      slots: slots ?? this.slots,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'signatoryCount': signatoryCount,
        'slots': slots.map((CertificateSignatorySlotDraft s) => s.toJson()).toList(growable: false),
      };

  factory CertificateEventSignatoryDraft.fromJson(Map<String, Object?> json) {
    final List<Object?> raw = json['slots'] as List<Object?>? ?? const <Object?>[];
    return CertificateEventSignatoryDraft(
      signatoryCount: (json['signatoryCount'] as num?)?.toInt() ?? 2,
      slots: raw
          .whereType<Map<Object?, Object?>>()
          .map((Map<Object?, Object?> m) => CertificateSignatorySlotDraft.fromJson(Map<String, Object?>.from(m)))
          .toList(growable: false),
    );
  }
}

class CertificateSignatorySlotDraft {
  const CertificateSignatorySlotDraft({
    this.userId = '',
    this.name = '',
    this.designation = '',
    this.signatureBase64 = '',
  });

  final String userId;
  final String name;
  final String designation;
  final String signatureBase64;

  Uint8List? get signatureBytes {
    if (signatureBase64.isEmpty) return null;
    try {
      return base64Decode(signatureBase64);
    } catch (_) {
      return null;
    }
  }

  CertificateSignatorySlotDraft copyWith({
    String? userId,
    String? name,
    String? designation,
    String? signatureBase64,
  }) {
    return CertificateSignatorySlotDraft(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      designation: designation ?? this.designation,
      signatureBase64: signatureBase64 ?? this.signatureBase64,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'userId': userId,
        'name': name,
        'designation': designation,
        'signatureBase64': signatureBase64,
      };

  factory CertificateSignatorySlotDraft.fromJson(Map<String, Object?> json) {
    return CertificateSignatorySlotDraft(
      userId: (json['userId'] as String? ?? '').trim(),
      name: (json['name'] as String? ?? '').trim(),
      designation: (json['designation'] as String? ?? '').trim(),
      signatureBase64: (json['signatureBase64'] as String? ?? '').trim(),
    );
  }
}

abstract final class CertificateEventSignatoryStore {
  CertificateEventSignatoryStore._();

  static String _key(String eventId) => 'certificate_signatories_${eventId.trim()}';

  static Future<CertificateEventSignatoryDraft?> load(String eventId) async {
    final String id = eventId.trim();
    if (id.isEmpty) return null;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key(id));
    if (raw == null || raw.isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return CertificateEventSignatoryDraft.fromJson(Map<String, Object?>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(String eventId, CertificateEventSignatoryDraft draft) async {
    final String id = eventId.trim();
    if (id.isEmpty) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(id), jsonEncode(draft.toJson()));
  }
}
