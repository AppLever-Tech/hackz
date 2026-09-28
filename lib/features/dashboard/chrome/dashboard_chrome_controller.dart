import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/ui/common/page_header_context_pill.dart';

/// Lets a dashboard body temporarily cover the full main panel (header + body).
class DashboardChromeController extends ChangeNotifier {
  Widget? _overlay;
  List<PageHeaderContextItem> _headerContextPills = const <PageHeaderContextItem>[];
  ValueChanged<int>? _selectPrimaryMenu;

  bool get hasOverlay => _overlay != null;

  Widget? get overlay => _overlay;

  /// Context pills shown under the chrome page title (org, department, …).
  List<PageHeaderContextItem> get headerContextPills => _headerContextPills;

  /// Wired by [DashboardPageTemplate] so body widgets can switch sidebar modules.
  void bindPrimaryMenuNavigator(ValueChanged<int>? selectMenu) {
    _selectPrimaryMenu = selectMenu;
  }

  void selectPrimaryMenu(int index) {
    _selectPrimaryMenu?.call(index);
  }

  void setHeaderContextPills(List<PageHeaderContextItem> pills) {
    final List<PageHeaderContextItem> next = pills
        .map(
          (PageHeaderContextItem item) => PageHeaderContextItem(
            icon: item.icon,
            label: item.label.trim(),
            kind: item.kind,
          ),
        )
        .where((PageHeaderContextItem item) => item.label.isNotEmpty)
        .toList(growable: false);
    if (listEquals(_headerContextPills, next)) return;
    _headerContextPills = next;
    notifyListeners();
  }

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
