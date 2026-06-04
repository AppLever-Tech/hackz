import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AttachmentUploadPreview extends StatelessWidget {
  const AttachmentUploadPreview({
    super.key,
    required this.files,
    required this.onPickFiles,
    required this.onRemoveFile,
    this.enabled = true,
    this.emptyText = 'No files uploaded yet.',
    this.uploadButtonLabel = 'Upload files',
  });

  final List<PlatformFile> files;
  final VoidCallback onPickFiles;
  final ValueChanged<PlatformFile> onRemoveFile;
  final bool enabled;
  final String emptyText;
  final String uploadButtonLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        OutlinedButton.icon(
          onPressed: enabled ? onPickFiles : null,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(uploadButtonLabel),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 42),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: files.isEmpty
              ? Text(
                  emptyText,
                  style: TextStyle(color: Colors.grey.shade600),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: files
                      .map(
                        (file) => Chip(
                          avatar: const Icon(Icons.insert_drive_file_outlined, size: 16),
                          label: Text(file.name, overflow: TextOverflow.ellipsis),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: enabled ? () => onRemoveFile(file) : null,
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
      ],
    );
  }
}
