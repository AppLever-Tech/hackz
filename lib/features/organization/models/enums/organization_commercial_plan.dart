/// Commercial plan on Control Plane `hkzOrganizations`.
/// Independent of organisation access status and event commercial access.
enum OrganizationCommercialPlan {
  perIdea('PER_IDEA', 'Per idea'),
  perEvent('PER_EVENT', 'Per event'),
  annual('ANNUAL', 'Annual');

  const OrganizationCommercialPlan(this.wireValue, this.label);

  final String wireValue;
  final String label;

  bool get isTimeBound => this == OrganizationCommercialPlan.annual;

  static const String _legacyAnnualToken = 'SUBSCRIPTION';

  static String _token(String raw) {
    return raw.trim().toUpperCase().replaceAll(RegExp(r'[\s_-]'), '');
  }

  static OrganizationCommercialPlan fromWire(Object? value) {
    final String token = _token(value as String? ?? '');
    if (token == _token(OrganizationCommercialPlan.perEvent.wireValue)) {
      return OrganizationCommercialPlan.perEvent;
    }
    if (token == _token(OrganizationCommercialPlan.annual.wireValue) ||
        token == _legacyAnnualToken) {
      return OrganizationCommercialPlan.annual;
    }
    return OrganizationCommercialPlan.perIdea;
  }
}
