import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../constants/app_icons.dart';
import '../models/attachment_model.dart';
import '../screens/common/app_dialog_template.dart';
import '../responsive/responsive_breakpoints.dart';
import '../responsive/responsive_dialog.dart';
import '../responsive/responsive_helper.dart';
import '../utils/attachment_service.dart';
import '../shared/inputs/network_image_compat.dart';
import 'responsive/responsive_filter_bar.dart';

class AttachmentPreviewRow extends StatefulWidget {
  const AttachmentPreviewRow({
    super.key,
    required this.entityType,
    required this.entityId,
    this.title = 'Attachments',
  });

  final AttachmentEntityType entityType;
  final String entityId;
  final String title;

  @override
  State<AttachmentPreviewRow> createState() => _AttachmentPreviewRowState();
}

class _AttachmentPreviewRowState extends State<AttachmentPreviewRow> {
  bool _loading = false;
  List<AttachmentModel>? _attachments;

  Future<void> _openViewer() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      _attachments ??= await AttachmentService.fetchActiveAttachments(
        entityType: widget.entityType,
        entityId: widget.entityId,
      );
      if (!mounted) return;
      await showAppDialog<void>(
        context: context,
        width: DialogWidthPreset.wide,
        child: AttachmentViewerDialog(
          title: widget.title,
          attachments: _attachments ?? const <AttachmentModel>[],
          embedded: true,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachments = _attachments ?? const <AttachmentModel>[];
    final imageCount = attachments.where((a) => a.attachmentType == AttachmentType.image).length;
    final videoCount = attachments.where((a) => a.attachmentType == AttachmentType.video).length;
    final docCount = attachments.length - imageCount - videoCount;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _openViewer,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE3E7F6)),
        ),
        child: Row(
          children: <Widget>[
            const Icon(AppIcons.attachments, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                attachments.isEmpty
                    ? '${widget.title} • Tap to load'
                    : '${widget.title} • ${attachments.length}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (attachments.isNotEmpty) ...<Widget>[
              _typeBadge(icon: AppIcons.attachmentImage, count: imageCount),
              const SizedBox(width: 6),
              _typeBadge(icon: AppIcons.attachmentVideo, count: videoCount),
              const SizedBox(width: 6),
              _typeBadge(icon: AppIcons.attachmentDocument, count: docCount),
              const SizedBox(width: 6),
            ],
            if (_loading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              const Icon(AppIcons.preview, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _typeBadge({required IconData icon, required int count}) {
    if (count <= 0) return const SizedBox.shrink();
    return Tooltip(
      message: '$count',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: const Color(0xFF5B628A)),
          const SizedBox(width: 2),
          Text('$count', style: const TextStyle(fontSize: 11, color: Color(0xFF5B628A))),
        ],
      ),
    );
  }
}

class AttachmentViewerDialog extends StatefulWidget {
  const AttachmentViewerDialog({
    super.key,
    required this.title,
    required this.attachments,
    this.embedded = false,
  });

  final String title;
  final List<AttachmentModel> attachments;

  /// When true, renders inside [showAppDialog] without an outer [Dialog] shell.
  final bool embedded;

  @override
  State<AttachmentViewerDialog> createState() => _AttachmentViewerDialogState();
}

class _AttachmentViewerDialogState extends State<AttachmentViewerDialog> with TickerProviderStateMixin {
  AttachmentType? _selectedTab;
  AttachmentModel? _selected;
  final Map<String, String> _resolvedUrlsById = <String, String>{};
  bool _resolvingUrls = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = _visibleTabs.firstOrNull;
    _selected = _currentList.firstOrNull;
    for (final item in widget.attachments) {
      _resolvedUrlsById[item.attachmentId] = item.downloadUrl;
    }
    _refreshStorageUrls();
  }

  List<AttachmentType> get _visibleTabs {
    final tabs = <AttachmentType>[];
    if (widget.attachments.any((a) => a.attachmentType == AttachmentType.image)) tabs.add(AttachmentType.image);
    if (widget.attachments.any((a) => a.attachmentType == AttachmentType.document || a.attachmentType == AttachmentType.pdf || a.attachmentType == AttachmentType.ppt)) {
      tabs.add(AttachmentType.document);
    }
    if (widget.attachments.any((a) => a.attachmentType == AttachmentType.video)) tabs.add(AttachmentType.video);
    return tabs;
  }

  List<AttachmentModel> get _currentList {
    if (_selectedTab == null) return const <AttachmentModel>[];
    return widget.attachments.where((a) {
      switch (_selectedTab!) {
        case AttachmentType.image:
          return a.attachmentType == AttachmentType.image;
        case AttachmentType.video:
          return a.attachmentType == AttachmentType.video;
        case AttachmentType.document:
          return a.attachmentType == AttachmentType.document ||
              a.attachmentType == AttachmentType.pdf ||
              a.attachmentType == AttachmentType.ppt;
        case AttachmentType.pdf:
        case AttachmentType.ppt:
          return false;
      }
    }).toList(growable: false);
  }

  Future<void> _openExternal(AttachmentModel file) async {
    final uri = Uri.tryParse(_resolvedUrlsById[file.attachmentId] ?? file.downloadUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _refreshStorageUrls() async {
    if (_resolvingUrls) return;
    setState(() => _resolvingUrls = true);
    try {
      for (final item in widget.attachments) {
        final path = item.storagePath.trim();
        if (path.isEmpty) continue;
        try {
          final refreshed = await FirebaseStorage.instance.ref(path).getDownloadURL();
          _resolvedUrlsById[item.attachmentId] = refreshed;
        } catch (e, st) {
          debugPrint(
            '[AttachmentViewerDialog] Failed to refresh URL for ${item.attachmentId} path=$path error=$e',
          );
          debugPrint('[AttachmentViewerDialog] stackTrace: $st');
        }
      }
    } finally {
      if (mounted) setState(() => _resolvingUrls = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _currentList;
    if (_selected != null && !list.contains(_selected)) {
      _selected = list.firstOrNull;
    }
    final body = LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically = widget.embedded ||
            ResponsiveHelper.isMobile(context) ||
            constraints.maxWidth < ResponsiveBreakpoints.tablet;
        final viewerHeight = widget.embedded
            ? (constraints.maxHeight.isFinite ? constraints.maxHeight.clamp(280.0, 560.0) : 420.0)
            : (ResponsiveHelper.isMobile(context) ? 360.0 : 520.0);

        final preview = AttachmentPreviewPane(
          attachment: _selected,
          resolvedUrl: _selected == null ? null : _resolveUrl(_selected!),
        );

        final grid = AttachmentGrid(
          attachments: list,
          resolveUrl: _resolveUrl,
          selectedId: _selected?.attachmentId,
          onTap: (a) => setState(() => _selected = a),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (!widget.embedded)
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            ResponsiveFilterChipRow(
              children: _visibleTabs
                  .map(
                    (tab) => ChoiceChip(
                      selected: _selectedTab == tab,
                      label: Text(_tabLabel(tab)),
                      onSelected: (_) => setState(() {
                        _selectedTab = tab;
                        _selected = _currentList.firstOrNull;
                      }),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 10),
            if (_resolvingUrls) const LinearProgressIndicator(minHeight: 2),
            if (_resolvingUrls) const SizedBox(height: 8),
            SizedBox(
              height: viewerHeight,
              child: stackVertically
                  ? Column(
                      children: <Widget>[
                        SizedBox(height: 140, child: grid),
                        const SizedBox(height: 10),
                        Expanded(child: preview),
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        SizedBox(width: 260, child: grid),
                        const SizedBox(width: 10),
                        Expanded(child: preview),
                      ],
                    ),
            ),
            const SizedBox(height: 8),
            if (_selected != null)
              ResponsiveWrapToolbar(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      '${_selected!.fileName} • ${AttachmentPreviewPane.formatSize(_selected!.sizeInBytes)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openExternal(_selected!),
                    icon: const Icon(AppIcons.openInNew, size: 16),
                    label: const Text('Open externally'),
                  ),
                  TextButton.icon(
                    onPressed: () => _openExternal(_selected!),
                    icon: const Icon(AppIcons.download, size: 16),
                    label: const Text('Download'),
                  ),
                ],
              ),
          ],
        );
      },
    );

    if (widget.embedded) {
      return body;
    }

    final maxW = ResponsiveDialogConstraints.maxWidth(context, preset: DialogWidthPreset.extraWide);
    final maxH = ResponsiveHelper.isMobile(context) ? double.infinity : 640.0;

    return Dialog(
      insetPadding: ResponsiveDialogConstraints.dialogInsets(context),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
        child: Padding(padding: const EdgeInsets.all(14), child: body),
      ),
    );
  }

  String _tabLabel(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return 'Images';
      case AttachmentType.video:
        return 'Videos';
      case AttachmentType.document:
      case AttachmentType.pdf:
      case AttachmentType.ppt:
        return 'Docs';
    }
  }

  String _resolveUrl(AttachmentModel attachment) {
    return _resolvedUrlsById[attachment.attachmentId] ?? attachment.downloadUrl;
  }
}

class AttachmentGrid extends StatelessWidget {
  const AttachmentGrid({
    super.key,
    required this.attachments,
    required this.resolveUrl,
    required this.selectedId,
    required this.onTap,
  });

  final List<AttachmentModel> attachments;
  final String Function(AttachmentModel attachment) resolveUrl;
  final String? selectedId;
  final ValueChanged<AttachmentModel> onTap;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const Center(child: Text('No attachments'));
    return GridView.builder(
      itemCount: attachments.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.95,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemBuilder: (_, i) => AttachmentTile(
        attachment: attachments[i],
        previewUrl: resolveUrl(attachments[i]),
        selected: attachments[i].attachmentId == selectedId,
        onTap: () => onTap(attachments[i]),
      ),
    );
  }
}

class AttachmentTile extends StatelessWidget {
  const AttachmentTile({
    super.key,
    required this.attachment,
    required this.previewUrl,
    required this.selected,
    required this.onTap,
  });

  final AttachmentModel attachment;
  final String previewUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isImage = attachment.attachmentType == AttachmentType.image;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFF4E62E8) : const Color(0xFFE2E6F2)),
          color: selected ? const Color(0xFFF1F4FF) : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: isImage
                    ? NetworkImageCompat(
                        url: previewUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (error) {
                          debugPrint(
                            '[AttachmentTile] Thumbnail load failed for ${attachment.attachmentId} '
                            'url=$previewUrl error=$error',
                          );
                          return _ImageLoadError(
                            title: 'Thumbnail load failed',
                            details: '$error',
                            type: attachment.attachmentType,
                          );
                        },
                      )
                    : Container(
                        width: double.infinity,
                        color: const Color(0xFFF5F7FD),
                        child: _FallbackIcon(type: attachment.attachmentType),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              attachment.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              _typeLabel(attachment.attachmentType),
              style: const TextStyle(fontSize: 11, color: Color(0xFF5E678E)),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(AttachmentType type) {
    switch (type) {
      case AttachmentType.image:
        return 'Image';
      case AttachmentType.video:
        return 'Video';
      case AttachmentType.pdf:
        return 'PDF';
      case AttachmentType.ppt:
        return 'PPT';
      case AttachmentType.document:
        return 'Document';
    }
  }
}

/// File-type-aware preview (image zoom, video player, document card).
class AttachmentPreviewPane extends StatelessWidget {
  const AttachmentPreviewPane({
    super.key,
    required this.attachment,
    required this.resolvedUrl,
  });

  final AttachmentModel? attachment;
  final String? resolvedUrl;

  static String formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = <String>['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int idx = 0;
    while (size >= 1024 && idx < units.length - 1) {
      size /= 1024;
      idx++;
    }
    return '${size.toStringAsFixed(size >= 10 || idx == 0 ? 0 : 1)} ${units[idx]}';
  }

  static String typeLabel(AttachmentType type) {
    return switch (type) {
      AttachmentType.image => 'Image',
      AttachmentType.video => 'Video',
      AttachmentType.pdf => 'PDF',
      AttachmentType.ppt => 'Presentation',
      AttachmentType.document => 'Document',
    };
  }

  static IconData typeIcon(AttachmentType type) {
    return switch (type) {
      AttachmentType.image => AppIcons.attachmentImage,
      AttachmentType.video => AppIcons.attachmentVideo,
      AttachmentType.pdf => AppIcons.attachmentPdf,
      AttachmentType.ppt => AppIcons.attachmentPpt,
      AttachmentType.document => AppIcons.attachmentDocument,
    };
  }

  @override
  Widget build(BuildContext context) {
    final item = attachment;
    if (item == null) return const Center(child: Text('Select an attachment'));
    switch (item.attachmentType) {
      case AttachmentType.image:
        final url = resolvedUrl ?? item.downloadUrl;
        return InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: NetworkImageCompat(
            url: url,
            fit: BoxFit.contain,
            errorBuilder: (error) {
              debugPrint(
                '[AttachmentContent] Full image load failed for ${item.attachmentId} '
                'url=$url error=$error',
              );
              return _ImageLoadError(
                title: 'Image request failed',
                details: '$error',
                type: item.attachmentType,
              );
            },
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
      final c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
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
              errorBuilder: (error) {
                debugPrint(
                  '[VideoContent] Thumbnail load failed url=${widget.thumbnailUrl} error=$error',
                );
                return const ColoredBox(color: Color(0xFFF1F4FB));
              },
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
    IconData icon;
    switch (type) {
      case AttachmentType.image:
        icon = AppIcons.attachmentImage;
      case AttachmentType.video:
        icon = AppIcons.attachmentVideo;
      case AttachmentType.pdf:
        icon = AppIcons.attachmentPdf;
      case AttachmentType.ppt:
        icon = AppIcons.attachmentPpt;
      case AttachmentType.document:
        icon = AppIcons.attachmentDocument;
    }
    return Center(child: Icon(icon, size: size, color: const Color(0xFF616A93)));
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
    final detailsLower = details.toLowerCase();
    final hint = detailsLower.contains('statuscode: 0')
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

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
