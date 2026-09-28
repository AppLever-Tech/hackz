import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_dialog_actions.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/ui/dialog/app_dialog_template.dart';
import '../../../core/ui/feedback/feedback.dart';
import '../../../core/ui/loading/loading.dart';
import '../../attachment/widgets/attachment_pick_field.dart';
import '../../user/models/user_model.dart';
import '../models/feedback_type.dart';
import '../services/hackz_feedback_service.dart';

Future<bool?> showFeedbackSubmitDialog({
  required BuildContext context,
  required UserModel user,
  String screenName = 'App',
}) {
  return showAppDialog<bool>(
    context: context,
    width: DialogWidthPreset.standard,
    maxWidth: 560,
    child: _FeedbackSubmitDialog(user: user, screenName: screenName),
  );
}

class _FeedbackSubmitDialog extends StatefulWidget {
  const _FeedbackSubmitDialog({
    required this.user,
    required this.screenName,
  });

  final UserModel user;
  final String screenName;

  @override
  State<_FeedbackSubmitDialog> createState() => _FeedbackSubmitDialogState();
}

class _FeedbackSubmitDialogState extends State<_FeedbackSubmitDialog> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  FeedbackType _type = FeedbackType.issue;
  PlatformFile? _screenshot;
  bool _busy = false;
  int _maxMb = 5;

  @override
  void initState() {
    super.initState();
    _description.addListener(() => setState(() {}));
    _loadLimits();
  }

  Future<void> _loadLimits() async {
    final int mb = await HackzFeedbackService.maxScreenshotSizeMb(widget.user);
    if (!mounted) return;
    setState(() => _maxMb = mb);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  int get _words => HackzFeedbackService.wordCount(_description.text);

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await HkzAsyncLoader.run<void>(
        context,
        title: 'Submitting feedback',
        message: 'Sending your feedback…',
        successMessage: 'Feedback submitted',
        task: () async {
          await HackzFeedbackService.submit(
            user: widget.user,
            type: _type,
            title: _title.text,
            description: _description.text,
            screenName: widget.screenName,
            screenshot: _screenshot,
          );
        },
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      final String msg = e is StateError ? e.message : e.toString();
      FeedbackService.showError(
        context,
        title: 'Could not submit',
        message: msg.replaceFirst('Bad state: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool overWords = _words > HackzFeedbackService.maxDescriptionWords;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(AppIcons.feedback, color: cs.primary),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Submit Feedback',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Report an Issue or suggest an Enhancement. Technical details are captured automatically.',
          style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.35),
        ),
        const SizedBox(height: 16),
        Text('Feedback Type *', style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: FeedbackType.values.map((FeedbackType t) {
            final bool selected = _type == t;
            return ChoiceChip(
              label: Text(t.label),
              selected: selected,
              onSelected: _busy ? null : (_) => setState(() => _type = t),
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _title,
          enabled: !_busy,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Title *',
            hintText: 'Short summary',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _description,
          enabled: !_busy,
          minLines: 4,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Description *',
            hintText: 'What happened / what would you like improved?',
            errorText: overWords
                ? 'Maximum ${HackzFeedbackService.maxDescriptionWords} words'
                : null,
            helperText:
                '$_words / ${HackzFeedbackService.maxDescriptionWords} words',
            helperStyle: TextStyle(
              color: overWords ? cs.error : cs.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Screenshot (optional)',
          style: TextStyle(fontWeight: FontWeight.w700, color: cs.onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          'PNG or JPEG · max $_maxMb MB · single image',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        AttachmentSingleImagePickField(
          file: _screenshot,
          enabled: !_busy,
          pickLabel: 'Upload screenshot',
          changeLabel: 'Change screenshot',
          onChanged: (PlatformFile? f) {
            final String? err = HackzFeedbackService.validateScreenshot(
              file: f,
              maxMb: _maxMb,
            );
            if (err != null) {
              FeedbackService.showError(context, title: 'Invalid screenshot', message: err);
              return;
            }
            setState(() => _screenshot = f);
          },
        ),
        const SizedBox(height: 18),
        ResponsiveDialogActions(
          children: <Widget>[
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _busy || overWords ? null : _submit,
              child: const Text('Submit'),
            ),
          ],
        ),
      ],
    );
  }
}
