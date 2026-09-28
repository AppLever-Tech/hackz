import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/ideathons/models/event_commercial_access.dart';

void main() {
  test('missing commercialAccess defaults to enabled so existing events keep working', () {
    expect(EventCommercialAccess.fromMap(null).status, EventCommercialAccessStatus.enabled);
    expect(EventCommercialAccess.fromMap(<String, dynamic>{}).isEnabled, isTrue);
    expect(EventCommercialAccess.fromMap(<String, dynamic>{}).isPending, isFalse);
    expect(EventCommercialAccess.fromMap(<String, dynamic>{}).allowsParticipation, isTrue);
  });

  test('pending awaits activation and still allows join and payment', () {
    final EventCommercialAccess pending = EventCommercialAccess.fromMap(
      <String, dynamic>{'status': 'pending'},
    );
    expect(pending.status, EventCommercialAccessStatus.pending);
    expect(pending.isPending, isTrue);
    expect(pending.isEnabled, isFalse);
    expect(pending.isRevoked, isFalse);
    expect(pending.allowsParticipation, isTrue);
    expect(pending.toMap(), <String, String>{'status': 'pending'});
  });

  test('disabled is revoked access and is not a lifecycle state', () {
    final EventCommercialAccess revoked = EventCommercialAccess.fromMap(
      <String, dynamic>{'status': 'disabled'},
    );
    expect(revoked.status, EventCommercialAccessStatus.disabled);
    expect(revoked.isPending, isFalse);
    expect(revoked.isRevoked, isTrue);
    expect(revoked.allowsParticipation, isFalse);
    expect(revoked.toMap(), <String, String>{'status': 'disabled'});
  });

  test('unknown status values default to enabled', () {
    expect(
      EventCommercialAccess.fromMap(<String, dynamic>{'status': 'draft'}).status,
      EventCommercialAccessStatus.enabled,
    );
  });
}
