/// Tenant-owned commercial access flag on an event. Not an event lifecycle state.
enum EventCommercialAccessStatus {
  pending,
  enabled,
  disabled;

  String get wireValue => name;

  static EventCommercialAccessStatus fromWire(Object? value) {
    final String normalized = (value as String? ?? '').trim().toLowerCase();
    if (normalized == pending.wireValue) return pending;
    if (normalized == disabled.wireValue) return disabled;
    return enabled;
  }
}

class EventCommercialAccess {
  const EventCommercialAccess({
    this.status = EventCommercialAccessStatus.enabled,
  });

  static const EventCommercialAccess enabled = EventCommercialAccess();
  static const EventCommercialAccess pending = EventCommercialAccess(
    status: EventCommercialAccessStatus.pending,
  );
  static const EventCommercialAccess disabled = EventCommercialAccess(
    status: EventCommercialAccessStatus.disabled,
  );

  final EventCommercialAccessStatus status;

  bool get isEnabled => status == EventCommercialAccessStatus.enabled;

  /// Awaiting SysAdmin activation (per-event).
  bool get isPending => status == EventCommercialAccessStatus.pending;

  /// SysAdmin revoked commercial access. Existing data is preserved.
  bool get isRevoked => status == EventCommercialAccessStatus.disabled;

  /// Join / pay / submit may continue until access is revoked.
  bool get allowsParticipation => !isRevoked;

  Map<String, dynamic> toMap() => <String, dynamic>{'status': status.wireValue};

  factory EventCommercialAccess.fromMap(Object? raw) {
    if (raw is Map) {
      return EventCommercialAccess(
        status: EventCommercialAccessStatus.fromWire(raw['status']),
      );
    }
    return EventCommercialAccess.enabled;
  }
}
