import 'package:flutter/material.dart';

import '../../../../core/firebase/approved_tenant_firebase.dart';
import '../../../../core/firebase/approved_tenant_project.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/ui/dialog/app_dialog_template.dart';
import '../../../../core/ui/feedback/feedback.dart';
import '../../../../core/ui/inputs/hackz_input_decoration.dart';
import '../../../../core/ui/loading/hkz_progress_indicator.dart';
import '../../../user/widgets/user_form_section.dart';

Future<bool> showRegisterWorkspaceDialog({required BuildContext context}) async {
  final bool? saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext _) => const RegisterWorkspaceDialog(),
  );
  return saved ?? false;
}

class RegisterWorkspaceDialog extends StatefulWidget {
  const RegisterWorkspaceDialog({super.key});

  @override
  State<RegisterWorkspaceDialog> createState() => _RegisterWorkspaceDialogState();
}

class _RegisterWorkspaceDialogState extends State<RegisterWorkspaceDialog> {
  final TextEditingController _label = TextEditingController();
  final TextEditingController _projectId = TextEditingController();
  final TextEditingController _apiKey = TextEditingController();
  final TextEditingController _appIdWeb = TextEditingController();
  final TextEditingController _appIdAndroid = TextEditingController();
  final TextEditingController _senderId = TextEditingController();
  final TextEditingController _bucket = TextEditingController();
  final TextEditingController _authDomain = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    _projectId.dispose();
    _apiKey.dispose();
    _appIdWeb.dispose();
    _appIdAndroid.dispose();
    _senderId.dispose();
    _bucket.dispose();
    _authDomain.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String hint) {
    return HackzInputDecoration.decorate(
      hintText: hint,
      prefixIcon: Icon(AppIcons.verification, size: 18, color: HackzInputDecoration.iconColor),
    );
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ApprovedTenantProject project = ApprovedTenantProject(
        projectId: _projectId.text.trim(),
        label: _label.text.trim(),
        apiKey: _apiKey.text.trim(),
        appIdWeb: _appIdWeb.text.trim(),
        appIdAndroid: _appIdAndroid.text.trim(),
        messagingSenderId: _senderId.text.trim(),
        storageBucket: _bucket.text.trim(),
        authDomain: _authDomain.text.trim(),
        createdAt: DateTime.now().toUtc(),
      );
      await ApprovedTenantFirebase.register(project);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
      await FeedbackService.showError(
        context,
        title: 'Unable to register workspace',
        message: '$e',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogTemplate(
      width: DialogWidthPreset.wide,
      maxWidth: 640,
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _busy ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6A38FF),
                  foregroundColor: Colors.white,
                ),
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: HkzProgressIndicator(size: 22, strokeWidth: 2.6),
                      )
                    : const Text('Register workspace'),
              ),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Register workspace',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hackz Admin only. Colleges never enter these values. Login uses the organisation code and the Control Plane catalog.',
            style: TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          UserFormSection(
            title: 'Approved Firebase project',
            subtitle: 'Copied from the Firebase console for this workspace.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                HackzInputDecoration.labeledField(
                  label: 'Label',
                  field: TextField(
                    controller: _label,
                    enabled: !_busy,
                    style: HackzInputDecoration.fieldTextStyle,
                    decoration: _decoration('College workspace name'),
                  ),
                ),
                const SizedBox(height: 10),
                HackzInputDecoration.labeledField(
                  label: 'Project ID',
                  required: true,
                  field: TextField(
                    controller: _projectId,
                    enabled: !_busy,
                    style: HackzInputDecoration.fieldTextStyle,
                    decoration: _decoration('firebase-project-id'),
                  ),
                ),
                const SizedBox(height: 10),
                HackzInputDecoration.labeledField(
                  label: 'API key',
                  required: true,
                  field: TextField(
                    controller: _apiKey,
                    enabled: !_busy,
                    style: HackzInputDecoration.fieldTextStyle,
                    decoration: _decoration('Web / Android API key'),
                  ),
                ),
                const SizedBox(height: 10),
                HackzInputDecoration.labeledField(
                  label: 'Web app ID',
                  field: TextField(
                    controller: _appIdWeb,
                    enabled: !_busy,
                    style: HackzInputDecoration.fieldTextStyle,
                    decoration: _decoration('1:…:web:…'),
                  ),
                ),
                const SizedBox(height: 10),
                HackzInputDecoration.labeledField(
                  label: 'Android app ID',
                  field: TextField(
                    controller: _appIdAndroid,
                    enabled: !_busy,
                    style: HackzInputDecoration.fieldTextStyle,
                    decoration: _decoration('1:…:android:…'),
                  ),
                ),
                const SizedBox(height: 10),
                HackzInputDecoration.labeledField(
                  label: 'Messaging sender ID',
                  required: true,
                  field: TextField(
                    controller: _senderId,
                    enabled: !_busy,
                    style: HackzInputDecoration.fieldTextStyle,
                    decoration: _decoration('Sender ID'),
                  ),
                ),
                const SizedBox(height: 10),
                HackzInputDecoration.labeledField(
                  label: 'Storage bucket',
                  required: true,
                  field: TextField(
                    controller: _bucket,
                    enabled: !_busy,
                    style: HackzInputDecoration.fieldTextStyle,
                    decoration: _decoration('project-id.appspot.com'),
                  ),
                ),
                const SizedBox(height: 10),
                HackzInputDecoration.labeledField(
                  label: 'Auth domain',
                  field: TextField(
                    controller: _authDomain,
                    enabled: !_busy,
                    style: HackzInputDecoration.fieldTextStyle,
                    decoration: _decoration('project-id.firebaseapp.com'),
                  ),
                ),
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFBE123C))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
