import 'package:flutter/material.dart';

class NetworkImageCompat extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, error, __) {
        if (errorBuilder != null) return errorBuilder!(error);
        return const SizedBox.shrink();
      },
    );
  }
}
