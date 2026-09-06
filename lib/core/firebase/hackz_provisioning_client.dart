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
    final HackzProvisioningIdentity identity = await HackzProvisioningIdentity.load();
    final String base = identity.invokeUrl.replaceAll(RegExp(r'/$'), '');
    if (base.isEmpty) {
      throw const HackzProvisioningException(
        'CONTROL_PLANE_UNAVAILABLE',
        'Set hkzProvisioningConfig/hackz.invokeUrl so SysAdmin can provision a College Admin.',
      );
    }

    final String? token = await HackzFirebase.sessionAuth.currentUser?.getIdToken();
    if (token == null || token.isEmpty) {
      throw const HackzProvisioningException(
        'UNAUTHORIZED',
        'Sign in as SysAdmin to provision a College Admin.',
      );
    }

    late final http.Response response;
    try {
      response = await http.post(
        Uri.parse('$base/provision-tenant-admin'),
        headers: <String, String>{
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, String>{
          'tenantProjectId': tenantProjectId,
          'organisationId': organisationId,
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'phone': phone,
        }),
      );
    } catch (_) {
      throw const HackzProvisioningException(
        'CONTROL_PLANE_UNAVAILABLE',
        'Unable to reach the provisioning service. Confirm invokeUrl and that the service is running.',
      );
    }

    Map<String, dynamic> body = <String, dynamic>{};
    try {
      final Object? decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    } catch (_) {}

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

  static String _actionableMessage({required String code, required String fallback}) {
    switch (code) {
      case 'PROVISIONING_NOT_AUTHORIZED':
        return 'The college must grant the Hackz provisioning identity, then Validate authorization.';
      case 'TENANT_NOT_READY':
        return 'Finish workspace connection and checks before creating the College Admin.';
      case 'ADMIN_EXISTS':
        return 'This organisation already has a College Admin.';
      case 'AUTH_CONFLICT':
        return fallback.isEmpty
            ? 'That phone or email is already used in this tenant.'
            : fallback;
      case 'UNAUTHORIZED':
        return 'Sign in as SysAdmin to provision a College Admin.';
      case 'CONTROL_PLANE_UNAVAILABLE':
        return 'The provisioning service cannot reach the Control Plane. Check the service is running.';
      case 'TENANT_NOT_FOUND':
        return 'This organisation is not in the Control Plane tenant registry.';
      case 'TENANT_AMBIGUOUS':
        return 'Multiple organisations share that Firebase project. Reconnect the correct workspace.';
      default:
        return fallback.isEmpty ? 'Unable to provision the College Admin.' : fallback;
    }
  }
}
