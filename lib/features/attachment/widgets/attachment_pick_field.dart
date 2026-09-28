import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:hackz/core/theme/app_icons.dart';

/// Single image proof — same picker + preview pattern as [showPaymentDialog].
class AttachmentSingleImagePickField extends StatelessWidget {
  const AttachmentSingleImagePickField({
    super.key,
    required this.file,
    required this.onChanged,
    this.enabled = true,
    this.pickLabel = 'Upload screenshot',
    this.changeLabel = 'Change screenshot',
    this.compact = false,
  });

  final PlatformFile? file;
  final ValueChanged<PlatformFile?> onChanged;
  final bool enabled;
  final String pickLabel;
  final String changeLabel;
  /// Sizes the button to its label so it can sit on the same row as a field label.
  final bool compact;

  Future<void> _pick() async {
    if (!enabled) return;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    onChanged(result.files.first);
  }

  @override
  Widget build(BuildContext context) {
    final Widget button = OutlinedButton.icon(
      onPressed: enabled ? _pick : null,
      icon: Icon(AppIcons.attachmentImage, size: compact ? 16 : 18),
      label: Text(file == null ? pickLabel : changeLabel),
      style: compact
          ? OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )
          : null,
    );

    return Column(
      crossAxisAlignment: compact ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
      children: <Widget>[
        if (compact) Align(alignment: Alignment.centerLeft, child: button) else button,
        if (file != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _PickedImagePreview(file: file!, compact: compact),
                ),
                const SizedBox(height: 6),
                Text(
                  file!.name,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6E7394)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PickedImagePreview extends StatelessWidget {
  const _PickedImagePreview({required this.file, this.compact = false});

  final PlatformFile file;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double height = compact ? 96 : 170;
    if (file.bytes != null && file.bytes!.isNotEmpty) {
      return Image.memory(
        Uint8List.fromList(file.bytes!),
        height: height,
        width: compact ? 160 : double.infinity,
        fit: BoxFit.cover,
      );
    }
    return Container(
      height: height,
      width: compact ? 160 : double.infinity,
      color: const Color(0xFFF1F4FA),
      alignment: Alignment.center,
      child: const Icon(AppIcons.attachmentImage),
    );
  }
}

/// Multiple local files before an entity id exists; uploads via [AttachmentService.uploadAttachments].
class AttachmentFilesPickField extends StatelessWidget {
  const AttachmentFilesPickField({
    super.key,
    required this.files,
    required this.onChanged,
    this.enabled = true,
    this.label = 'Attachments',
    this.hint = 'Add files to include with this submission (images, PDFs, documents).',
    this.allowedExtensions,
  });

  final List<PlatformFile> files;
  final ValueChanged<List<PlatformFile>> onChanged;
  final bool enabled;
  final String label;
  final String hint;
  final List<String>? allowedExtensions;

  Future<void> _pick() async {
    if (!enabled) return;
    final List<String>? extensions = allowedExtensions;
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: extensions == null || extensions.isEmpty ? FileType.any : FileType.custom,
      allowedExtensions: extensions == null || extensions.isEmpty ? null : extensions,
    );
    if (result == null || result.files.isEmpty) return;
    final next = List<PlatformFile>.from(files);
    for (final file in result.files) {
      final dup = next.any((f) => f.name == file.name && f.size == file.size);
      if (!dup) next.add(file);
    }
    onChanged(next);
  }

  void _removeAt(int index) {
    if (!enabled) return;
    final next = List<PlatformFile>.from(files)..removeAt(index);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 6),
        Text(hint, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: enabled ? _pick : null,
          icon: const Icon(AppIcons.attachments, size: 18),
          label: const Text('Add files'),
        ),
        if (files.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List<Widget>.generate(files.length, (int i) {
              final f = files[i];
              return InputChip(
                label: Text(f.name, overflow: TextOverflow.ellipsis),
                onDeleted: enabled ? () => _removeAt(i) : null,
              );
            }),
          ),
        ],
      ],
    );
  }
}
