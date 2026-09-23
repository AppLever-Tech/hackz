import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/features/exports/certificate/certificate_event_signatory_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('round-trips signatory draft per event', () async {
    const CertificateEventSignatoryDraft draft = CertificateEventSignatoryDraft(
      signatoryCount: 3,
      slots: <CertificateSignatorySlotDraft>[
        CertificateSignatorySlotDraft(userId: 'u1', name: 'Pat', designation: 'HOD'),
        CertificateSignatorySlotDraft(name: 'Manual', designation: 'Principal'),
        CertificateSignatorySlotDraft(),
      ],
    );

    await CertificateEventSignatoryStore.save('event-42', draft);
    final CertificateEventSignatoryDraft? loaded = await CertificateEventSignatoryStore.load('event-42');

    expect(loaded?.signatoryCount, 3);
    expect(loaded?.slots.first.name, 'Pat');
    expect(loaded?.slots[1].designation, 'Principal');
  });
}
