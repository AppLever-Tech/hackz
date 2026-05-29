import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class NetworkImageCompat extends StatefulWidget {
  const NetworkImageCompat({
    super.key,
    required this.url,
    required this.fit,
    this.width,
    this.height,
    this.errorBuilder,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(Object error)? errorBuilder;

  @override
  State<NetworkImageCompat> createState() => _NetworkImageCompatState();
}

class _NetworkImageCompatState extends State<NetworkImageCompat> {
  static final Set<String> _registeredTypes = <String>{};
  bool _hasError = false;
  String? _errorText;

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
      _errorText = null;
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
        ..draggable = false;
      img.onError.listen((event) {
        final msg = 'HTML image failed to load: ${widget.url}';
        debugPrint('[NetworkImageCompatWeb] $msg');
        if (mounted) {
          setState(() {
            _hasError = true;
            _errorText = msg;
          });
        }
      });
      return img;
    });
    _registeredTypes.add(_viewType);
  }

  @override
  Widget build(BuildContext context) {
    final child = _hasError
        ? (widget.errorBuilder?.call(_errorText ?? 'Image load failed') ?? const SizedBox.shrink())
        : HtmlElementView(viewType: _viewType);

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
