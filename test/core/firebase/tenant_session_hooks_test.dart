import 'package:flutter_test/flutter_test.dart';
import 'package:hackz/core/firebase/tenant_session_hooks.dart';

void main() {
  setUp(TenantSessionHooks.resetForTest);
  tearDown(TenantSessionHooks.resetForTest);

  test('rebind notifies registered caches once per hook', () {
    var count = 0;
    void hook() => count++;
    TenantSessionHooks.addOnRebound(hook);
    TenantSessionHooks.addOnRebound(hook);

    TenantSessionHooks.notifyRebound();
    TenantSessionHooks.notifyRebound();

    expect(count, 2);
  });

  test('removed hooks are not notified', () {
    var count = 0;
    void hook() => count++;
    TenantSessionHooks.addOnRebound(hook);
    TenantSessionHooks.removeOnRebound(hook);
    TenantSessionHooks.notifyRebound();
    expect(count, 0);
  });
}
