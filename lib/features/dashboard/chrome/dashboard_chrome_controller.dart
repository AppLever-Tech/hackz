import 'package:flutter/material.dart';

/// Lets a dashboard body temporarily cover the full main panel (header + body).
class DashboardChromeController extends ChangeNotifier {
  Widget? _overlay;

  bool get hasOverlay => _overlay != null;

  Widget? get overlay => _overlay;

  void showOverlay(Widget content) {
    _overlay = content;
    notifyListeners();
  }

  void clearOverlay() {
    if (_overlay == null) return;
    _overlay = null;
    notifyListeners();
  }
}
