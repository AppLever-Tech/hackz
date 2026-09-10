/// How an organisation is commercially entitled to use Hackz.
enum OrganizationAccessMode {
  perIdea,
  perEvent,
  subscription;

  String get wireValue => name;

  String get label {
    switch (this) {
      case OrganizationAccessMode.perIdea:
        return 'Per idea';
      case OrganizationAccessMode.perEvent:
        return 'Per event';
      case OrganizationAccessMode.subscription:
        return 'Subscription';
    }
  }

  static OrganizationAccessMode fromWire(Object? value) {
    final String normalized = (value as String? ?? '').trim().toLowerCase();
    for (final OrganizationAccessMode mode in OrganizationAccessMode.values) {
      if (mode.wireValue.toLowerCase() == normalized) return mode;
    }
    return OrganizationAccessMode.perIdea;
  }
}
