import 'dart:convert';

import 'package:http/http.dart' as http;

import 'hackz_firebase.dart';
import 'hackz_provisioning_identity.dart';

class HackzProvisioningException implements Exception {
  const HackzProvisioningException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => message;
}

class HackzProvisioningResult {
  const HackzProvisioningResult({
    required this.userId,
    required this.phone,
    required this.email,
    required this.organisationId,
  });

  final String userId;
  final String phone;
  final String email;
  final String organisationId;
}

class HackzEventEntitlementResult {
  const HackzEventEntitlementResult({
    required this.skipped,
    required this.existing,
    required this.entitlementId,
    required this.organisationId,
    required this.eventId,
  });

  final bool skipped;
  final bool existing;
  final String entitlementId;
  final String organisationId;
  final String eventId;

  bool get registered => !skipped;
}

class HackzEventEntitlementStatusResult {
  const HackzEventEntitlementStatusResult({
    required this.unchanged,
    required this.entitlementId,
    required this.organisationId,
    required this.eventId,
    required this.status,
  });

  final bool unchanged;
  final String entitlementId;
  final String organisationId;
  final String eventId;
  final String status;
}

/// Invokes the privileged provisioning service. Not used for later College Admin edits.
abstract final class HackzProvisioningClient {
  HackzProvisioningClient._();

  static Future<HackzProvisioningResult> provisionTenantAdmin({
    required String tenantProjectId,
    required String organisationId,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
  }) async {
    final Map<String, dynamic> body = await _postJson(
      path: '/provision-tenant-admin',
      payload: <String, String>{
        'tenantProjectId': tenantProjectId,
        'organisationId': organisationId,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
      },
      missingTokenMessage: 'Sign in as SysAdmin to provision a College Admin.',
    );

    if (body['ok'] == true) {
      return HackzProvisioningResult(
        userId: (body['userId'] as String? ?? '').trim(),
        phone: (body['phone'] as String? ?? '').trim(),
        email: (body['email'] as String? ?? '').trim(),
        organisationId: (body['organisationId'] as String? ?? '').trim(),
      );
    }

    throw HackzProvisioningException(
      (body['code'] as String? ?? 'WRITE_FAILED').trim(),
      _actionableMessage(
        code: (body['code'] as String? ?? '').trim(),
        fallback: (body['message'] as String? ?? 'Unable to provision the College Admin.').trim(),
      ),
    );
  }

  /// Registers Control Plane event entitlement metadata for a per-event organisation.
  ///
  /// Uses the signed-in tenant session. Does not write tenant event business data.
  static Future<HackzEventEntitlementResult> registerEventEntitlement({
    required String organisationId,
    required String eventId,
    required String eventName,
    required String eventType,
  }) async {
    final Map<String, dynamic> body = await _postJson(
      path: '/register-event-entitlement',
      payload: <String, String>{
        'organisationId': organisationId,
        'eventId': eventId,
        'eventName': eventName,
        'eventType': eventType,
      },
      missingTokenMessage: 'Sign in as a Department Admin to register event access.',
    );

    if (body['ok'] == true) {
      return HackzEventEntitlementResult(
        skipped: body['skipped'] == true,
        existing: body['existing'] == true,
        entitlementId: (body['entitlementId'] as String? ?? '').trim(),
        organisationId: (body['organisationId'] as String? ?? '').trim(),
        eventId: (body['eventId'] as String? ?? '').trim(),
      );
    }

    throw HackzProvisioningException(
      (body['code'] as String? ?? 'WRITE_FAILED').trim(),
      (body['message'] as String? ?? 'Unable to register event access.').trim(),
    );
  }

  /// SysAdmin activate/disable. Updates Control Plane licensing then tenant commercialAccess.
  static Future<HackzEventEntitlementStatusResult> setEventEntitlementStatus({
    required String organisationId,
    required String eventId,
    required String status,
  }) async {
    final Map<String, dynamic> body = await _postJson(
      path: '/set-event-entitlement-status',
      payload: <String, String>{
        'organisationId': organisationId,
        'eventId': eventId,
        'status': status,
      },
      missingTokenMessage: 'Sign in as SysAdmin to update event access.',
    );

    if (body['ok'] == true) {
      return HackzEventEntitlementStatusResult(
        unchanged: body['unchanged'] == true,
        entitlementId: (body['entitlementId'] as String? ?? '').trim(),
        organisationId: (body['organisationId'] as String? ?? '').trim(),
        eventId: (body['eventId'] as String? ?? '').trim(),
        status: (body['status'] as String? ?? '').trim(),
      );
    }

    throw HackzProvisioningException(
      (body['code'] as String? ?? 'WRITE_FAILED').trim(),
      _actionableMessage(
        code: (body['code'] as String? ?? '').trim(),
        fallback: (body['message'] as String? ?? 'Unable to update event access.').trim(),
      ),
    );
  }

  static Future<Map<String, dynamic>> _postJson({
    required String path,
    required Map<String, String> payload,
    required String missingTokenMessage,
  }) async {
    final HackzProvisioningIdentity identity = await HackzProvisioningIdentity.load();
    final String base = identity.invokeUrl.replaceAll(RegExp(r'/$'), '');
    if (base.isEmpty) {
      throw const HackzProvisioningException(
        'CONTROL_PLANE_UNAVAILABLE',
        'Set hkzProvisioningConfig/hackz.invokeUrl to the Cloud Run provisioner (or http://localhost:8787 for local development).',
      );
    }

    final String? token = await HackzFirebase.sessionAuth.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      throw HackzProvisioningException('UNAUTHORIZED', missingTokenMessage);
    }

    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$base$path'),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
    } catch (_) {
      throw const HackzProvisioningException(
        'CONTROL_PLANE_UNAVAILABLE',
        'Unable to reach the provisioning service. Confirm hkzProvisioningConfig/hackz.invokeUrl.',
      );
    }

    Map<String, dynamic> body = <String, dynamic>{};
    try {
      final Object? decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}
    return body;
  }

  static String _actionableMessage({required String code, required String fallback}) {
    switch (code) {
      case 'PROVISIONING_NOT_AUTHORIZED':
        return fallback.isEmpty
            ? 'The college must grant the Hackz provisioning identity, then Validate authorization.'
            : fallback;
      case 'TENANT_NOT_READY':
        return 'Finish workspace connection and checks before creating the College Admin.';
      case 'ADMIN_EXISTS':
        return 'This organisation already has a College Admin.';
      case 'AUTH_CONFLICT':
        return fallback.isEmpty
            ? 'That phone or email is already used in this tenant.'
            : fallback;
      case 'UNAUTHORIZED':
        return fallback.isEmpty ? 'Sign in as SysAdmin to continue.' : fallback;
      case 'CONTROL_PLANE_UNAVAILABLE':
        return 'The provisioning service cannot reach the Control Plane.';
      case 'TENANT_NOT_FOUND':
        return 'This organisation is not in the Control Plane tenant registry.';
      case 'TENANT_AMBIGUOUS':
        return 'Multiple organisations share that Firebase project. Reconnect the correct workspace.';
      default:
        return fallback.isEmpty ? 'Unable to complete the provisioning operation.' : fallback;
    }
  }
}
