import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../../media/remote_image_logging.dart';

class NetworkImageCompat extends StatefulWidget {
  const NetworkImageCompat({
    super.key,
    required this.url,
    required this.fit,
    this.width,
    this.height,
    this.logTag,
    this.logContext,
    this.errorBuilder,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final String? logTag;
  final String? logContext;
  final Widget Function(Object error)? errorBuilder;

  @override
  State<NetworkImageCompat> createState() => _NetworkImageCompatState();
}

class _NetworkImageCompatState extends State<NetworkImageCompat> {
  static final Set<String> _registeredTypes = <String>{};
  bool _hasError = false;
  Object? _error;

  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'net-img-${widget.url.hashCode}-${widget.fit.name}';
    _registerFactoryIfNeeded();
  }

  @override
  void didUpdateWidget(covariant NetworkImageCompat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.fit != widget.fit) {
      _hasError = false;
      _error = null;
    }
  }

  void _onImageError() {
    const String msg = 'HTML image element failed to load';
    logRemoteImageLoadFailure(
      tag: widget.logTag ?? 'NetworkImageCompat',
      url: widget.url,
      error: msg,
      context: widget.logContext,
    );
    if (mounted) {
      setState(() {
        _hasError = true;
        _error = msg;
      });
    }
  }

  void _registerFactoryIfNeeded() {
    if (_registeredTypes.contains(_viewType)) return;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int _) {
      final img = html.ImageElement()
        ..src = widget.url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = _cssFit(widget.fit)
        ..style.display = 'block'
        // Let Flutter ancestors (e.g. ContextLaunchSurface) receive taps.
        ..style.pointerEvents = 'none'
        ..draggable = false;
      img.onError.listen((_) => _onImageError());
      return img;
    });
    _registeredTypes.add(_viewType);
  }

  @override
  Widget build(BuildContext context) {
    final child = _hasError
        ? (widget.errorBuilder?.call(_error ?? 'Image load failed') ??
            const SizedBox.shrink())
        : IgnorePointer(
            child: HtmlElementView(viewType: _viewType),
          );

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: child,
    );
  }

  String _cssFit(BoxFit fit) {
    switch (fit) {
      case BoxFit.contain:
        return 'contain';
      case BoxFit.cover:
        return 'cover';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.fitHeight:
        return 'scale-down';
      case BoxFit.fitWidth:
        return 'scale-down';
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scale-down';
    }
  }
}
