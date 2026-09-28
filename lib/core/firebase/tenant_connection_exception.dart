/// User-facing failure when a tenant Firebase connection cannot be established.
enum TenantConnectionFailure {
  invalidCode,
  notFound,
  inactive,
  unapproved,
  unavailable,
  conflict,
  unauthorized,
}

class TenantConnectionException implements Exception {
  const TenantConnectionException(this.failure, {String? message}) : _message = message;

  final TenantConnectionFailure failure;
  final String? _message;

  String get message {
    if ((_message ?? '').trim().isNotEmpty) return _message!.trim();
    switch (failure) {
      case TenantConnectionFailure.invalidCode:
        return 'That organisation code is not valid.';
      case TenantConnectionFailure.notFound:
        return 'No organisation was found for that code.';
      case TenantConnectionFailure.inactive:
        return 'This organisation is not active yet.';
      case TenantConnectionFailure.unapproved:
        return 'This organisation’s workspace is not approved.';
      case TenantConnectionFailure.unavailable:
        return 'The organisation workspace is unavailable right now. Try again.';
      case TenantConnectionFailure.conflict:
        return 'This organisation code cannot be used. Contact Hackz support.';
      case TenantConnectionFailure.unauthorized:
        return 'Platform administration is required to open this organisation.';
    }
  }

  @override
  String toString() => message;
}
