import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/core/firebase/last_organisation_code_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('saves a normalized organisation code for the next visit', () async {
    await LastOrganisationCodeStore.save('  hkz-s7k4pm  ');
    expect(await LastOrganisationCodeStore.read(), 'HKZ-S7K4PM');
  });

  test('ignores invalid codes and does not remember them', () async {
    await LastOrganisationCodeStore.save('HKZ-S7K4PM');
    await LastOrganisationCodeStore.save('not-a-code');
    expect(await LastOrganisationCodeStore.read(), 'HKZ-S7K4PM');
  });

  test('returns null when nothing has been saved', () async {
    expect(await LastOrganisationCodeStore.read(), isNull);
  });

  test('platform admin session is remembered separately from organisation code', () async {
    await LastOrganisationCodeStore.save('HKZ-S7K4PM');
    await LastOrganisationCodeStore.savePlatformAdminSession();
    expect(await LastOrganisationCodeStore.isPlatformAdminSession(), isTrue);
    expect(await LastOrganisationCodeStore.read(), 'HKZ-S7K4PM');

    await LastOrganisationCodeStore.save('HKZ-S7K4PM');
    expect(await LastOrganisationCodeStore.isPlatformAdminSession(), isFalse);

    await LastOrganisationCodeStore.savePlatformAdminSession();
    await LastOrganisationCodeStore.clearPlatformAdminSession();
    expect(await LastOrganisationCodeStore.isPlatformAdminSession(), isFalse);
  });
}
