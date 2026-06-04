import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:hackz/features/attachment/models/attachment_model.dart';
import 'package:hackz/features/attachment/utils/attachment_preview_utils.dart';
import 'package:hackz/shared/inputs/network_image_compat.dart';

/// File-type-aware preview (image zoom, video player, document card) for attachment workspace.
class AttachmentPreviewPane extends StatelessWidget {
  const AttachmentPreviewPane({
    super.key,
    required this.attachment,
    required this.resolvedUrl,
  });

  final AttachmentModel? attachment;
  final String? resolvedUrl;

  @override
  Widget build(BuildContext context) {
    final AttachmentModel? item = attachment;
    if (item == null) return const Center(child: Text('Select an attachment'));
    switch (item.attachmentType) {
      case AttachmentType.image:
        final String url = resolvedUrl ?? item.downloadUrl;
        return InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: NetworkImageCompat(
            url: url,
            fit: BoxFit.contain,
            logTag: 'AttachmentContent',
            logContext: 'attachmentId=${item.attachmentId}',
            errorBuilder: (Object error) => _ImageLoadError(
              title: 'Image request failed',
              details: '$error',
              type: item.attachmentType,
            ),
          ),
        );
      case AttachmentType.video:
        return _VideoContent(url: resolvedUrl ?? item.downloadUrl, thumbnailUrl: item.thumbnailUrl);
      case AttachmentType.pdf:
      case AttachmentType.ppt:
      case AttachmentType.document:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _FallbackIcon(type: item.attachmentType, size: 54),
              const SizedBox(height: 10),
              Text(item.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              const Text('Open externally to view this file.'),
            ],
          ),
        );
    }
  }
}

class _VideoContent extends StatefulWidget {
  const _VideoContent({required this.url, required this.thumbnailUrl});

  final String url;
  final String? thumbnailUrl;

  @override
  State<_VideoContent> createState() => _VideoContentState();
}

class _VideoContentState extends State<_VideoContent> {
  VideoPlayerController? _controller;
  bool _loading = false;
  String? _errorMessage;

  Future<void> _play() async {
    if (_controller != null || _loading) return;
    setState(() => _loading = true);
    try {
      final VideoPlayerController c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await c.initialize();
      await c.setLooping(false);
      await c.play();
      if (!mounted) return;
      setState(() {
        _controller = c;
        _loading = false;
        _errorMessage = null;
      });
    } catch (e, st) {
      debugPrint('[VideoContent] Video init/play failed url=${widget.url} error=$e');
      debugPrint('[VideoContent] stackTrace: $st');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = '$e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if ((widget.thumbnailUrl ?? '').isNotEmpty)
            NetworkImageCompat(
              url: widget.thumbnailUrl!,
              fit: BoxFit.cover,
              logTag: 'VideoContent',
              logContext: 'thumbnail',
              errorBuilder: (_) => const ColoredBox(color: Color(0xFFF1F4FB)),
            )
          else
            Container(color: const Color(0xFFF1F4FB)),
          if (_errorMessage != null)
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEF0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFCCD2)),
                ),
                child: Text(
                  _errorMessage!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFB93838), fontSize: 12),
                ),
              ),
            ),
          Center(
            child: FilledButton.icon(
              onPressed: _loading ? null : _play,
              icon: const Icon(Icons.play_arrow),
              label: Text(_loading ? 'Loading...' : 'Play video'),
            ),
          ),
        ],
      );
    }
    return Column(
      children: <Widget>[
        Expanded(child: AspectRatio(aspectRatio: _controller!.value.aspectRatio, child: VideoPlayer(_controller!))),
        Row(
          children: <Widget>[
            IconButton(
              icon: Icon(_controller!.value.isPlaying ? Icons.pause : Icons.play_arrow),
              onPressed: () async {
                if (_controller!.value.isPlaying) {
                  await _controller!.pause();
                } else {
                  await _controller!.play();
                }
                if (mounted) setState(() {});
              },
            ),
            Expanded(
              child: VideoProgressIndicator(_controller!, allowScrubbing: true),
            ),
          ],
        ),
      ],
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({required this.type, this.size = 28});

  final AttachmentType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(AttachmentPreviewUtils.typeIcon(type), size: size, color: const Color(0xFF616A93)),
    );
  }
}

class _ImageLoadError extends StatelessWidget {
  const _ImageLoadError({
    required this.title,
    required this.details,
    required this.type,
  });

  final String title;
  final String details;
  final AttachmentType type;

  @override
  Widget build(BuildContext context) {
    final String detailsLower = details.toLowerCase();
    final String? hint = detailsLower.contains('statuscode: 0')
        ? 'Likely CORS/network blocked. Check browser console and Firebase Storage CORS.'
        : null;
    return Container(
      width: double.infinity,
      color: const Color(0xFFFDF2F2),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _FallbackIcon(type: type),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB93838)),
          ),
          const SizedBox(height: 2),
          Text(
            details,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Color(0xFFB93838)),
          ),
          if (hint != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              hint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Color(0xFF8A2B2B)),
            ),
          ],
        ],
      ),
    );
  }
}
