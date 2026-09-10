import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/ideathons/models/event_commercial_access.dart';

void main() {
  test('missing commercialAccess defaults to enabled so existing events keep working', () {
    expect(EventCommercialAccess.fromMap(null).status, EventCommercialAccessStatus.enabled);
    expect(EventCommercialAccess.fromMap(<String, dynamic>{}).isPending, isFalse);
  });

  test('disabled is pending activation and is not a lifecycle state', () {
    final EventCommercialAccess pending = EventCommercialAccess.fromMap(
      <String, dynamic>{'status': 'disabled'},
    );
    expect(pending.status, EventCommercialAccessStatus.disabled);
    expect(pending.isPending, isTrue);
    expect(pending.toMap(), <String, String>{'status': 'disabled'});
  });

  test('unknown status values default to enabled', () {
    expect(
      EventCommercialAccess.fromMap(<String, dynamic>{'status': 'draft'}).status,
      EventCommercialAccessStatus.enabled,
    );
  });
}
