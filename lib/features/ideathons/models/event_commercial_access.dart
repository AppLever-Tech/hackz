/// Tenant-owned commercial access flag on an event. Not an event lifecycle state.
enum EventCommercialAccessStatus {
  enabled,
  disabled;

  String get wireValue => name;

  static EventCommercialAccessStatus fromWire(Object? value) {
    final String normalized = (value as String? ?? '').trim().toLowerCase();
    if (normalized == disabled.wireValue) return disabled;
    return enabled;
  }
}

class EventCommercialAccess {
  const EventCommercialAccess({
    this.status = EventCommercialAccessStatus.enabled,
  });

  static const EventCommercialAccess enabled = EventCommercialAccess();
  static const EventCommercialAccess disabled = EventCommercialAccess(
    status: EventCommercialAccessStatus.disabled,
  );

  final EventCommercialAccessStatus status;

  /// Pending activation for a per-event organisation. Does not change lifecycle.
  bool get isPending => status == EventCommercialAccessStatus.disabled;

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
