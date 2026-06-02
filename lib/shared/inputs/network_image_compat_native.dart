import 'package:flutter/material.dart';

import '../media/remote_image_logging.dart';

class NetworkImageCompat extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, Object error, __) {
        if (logTag != null) {
          logRemoteImageLoadFailure(
            tag: logTag!,
            url: url,
            error: error,
            context: logContext,
          );
        }
        if (errorBuilder != null) return errorBuilder!(error);
        return const SizedBox.shrink();
      },
    );
  }
}
