import 'package:flutter/foundation.dart';

/// Callbacks fired when [HackzFirebase.current] is rebound.
///
/// Feature caches register here so tenant switches (login, logout, SysAdmin
/// open-organisation / Platform console) never keep the previous tenant's data.
abstract final class TenantSessionHooks {
  TenantSessionHooks._();

  static final List<void Function()> _onRebound = <void Function()>[];

  static void addOnRebound(void Function() hook) {
    if (_onRebound.contains(hook)) return;
    _onRebound.add(hook);
  }

  static void removeOnRebound(void Function() hook) {
    _onRebound.remove(hook);
  }

  static void notifyRebound() {
    for (final void Function() hook in List<void Function()>.from(_onRebound)) {
      hook();
    }
  }

  @visibleForTesting
  static void resetForTest() {
    _onRebound.clear();
  }
}
