import 'dart:ui';

import 'package:flutter/material.dart';

import 'hkz_loading_card.dart';
import 'hkz_loading_controller.dart';
import 'hkz_loading_theme.dart';

/// Global floating loading overlay (root overlay, blocks interaction).
abstract final class HkzLoadingOverlay {
  static OverlayEntry? _entry;
  static HkzLoadingController? _controller;
  static _OverlayHostState? _hostState;

  static bool get isVisible => _entry != null;

  static HkzLoadingController? get controller => _controller;

  /// Shows the overlay and returns a controller for [updateMessage].
  static HkzLoadingController show(
    BuildContext context, {
    required String title,
    String? message,
    double? progress,
  }) {
    hide();

    final HkzLoadingController controller = HkzLoadingController(
      title: title,
      message: message,
      progress: progress,
    );
    _controller = controller;

    final OverlayState overlay = Overlay.of(context, rootOverlay: true);
    _entry = OverlayEntry(
      builder: (BuildContext context) => _OverlayHost(
        controller: controller,
        onDismissed: HkzLoadingOverlay._tearDown,
      ),
    );
    overlay.insert(_entry!);
    return controller;
  }

  static void updateMessage(
    BuildContext context, {
    String? title,
    String? message,
    double? progress,
  }) {
    _controller?.update(title: title, message: message, progress: progress);
  }

  static Future<void> completeSuccess({
    String? message,
    Duration hold = const Duration(milliseconds: 650),
  }) async {
    _controller?.setSuccess(message: message);
    await Future<void>.delayed(hold);
    hide();
  }

  static void showError(
    String message, {
    VoidCallback? onRetry,
  }) {
    _controller?.setError(message, onRetry: onRetry);
  }

  static void hide() {
    if (_entry == null) return;
    if (_hostState != null) {
      _hostState!.dismiss();
    } else {
      _tearDown();
    }
  }

  static void _tearDown() {
    _entry?.remove();
    _entry = null;
    _controller = null;
    _hostState = null;
  }
}

class _OverlayHost extends StatefulWidget {
  const _OverlayHost({
    required this.controller,
    required this.onDismissed,
  });

  final HkzLoadingController controller;
  final VoidCallback onDismissed;

  @override
  State<_OverlayHost> createState() => _OverlayHostState();
}

class _OverlayHostState extends State<_OverlayHost> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    HkzLoadingOverlay._hostState = this;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  void dismiss() {
    if (!mounted) return;
    setState(() => _visible = false);
  }

  @override
  void dispose() {
    if (HkzLoadingOverlay._hostState == this) {
      HkzLoadingOverlay._hostState = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          GestureDetector(
            onTap: () {},
            behavior: HitTestBehavior.opaque,
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: _visible
                  ? HkzLoadingTheme.enterDuration
                  : HkzLoadingTheme.exitDuration,
              curve: _visible ? HkzLoadingTheme.enterCurve : HkzLoadingTheme.exitCurve,
              onEnd: () {
                if (!_visible) widget.onDismissed();
              },
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: HkzLoadingTheme.scrim),
              ),
            ),
          ),
          Center(
            child: AnimatedScale(
              scale: _visible ? 1 : 0.94,
              duration: _visible
                  ? HkzLoadingTheme.enterDuration
                  : HkzLoadingTheme.exitDuration,
              curve: _visible ? HkzLoadingTheme.enterCurve : HkzLoadingTheme.exitCurve,
              child: AnimatedOpacity(
                opacity: _visible ? 1 : 0,
                duration: _visible
                    ? HkzLoadingTheme.enterDuration
                    : HkzLoadingTheme.exitDuration,
                child: HkzLoadingCard(controller: widget.controller),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
