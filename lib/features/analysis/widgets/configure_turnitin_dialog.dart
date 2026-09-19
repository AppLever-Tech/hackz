import 'package:flutter/material.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/ui/dialog/app_dialog_template.dart';
import '../../../core/ui/inputs/hackz_input_decoration.dart';

Future<Map<String, String>?> showConfigureTurnitinDialog({
  required BuildContext context,
}) async {
  return showDialog<Map<String, String>>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext _) => const _ConfigureTurnitinDialog(),
  );
}

class _ConfigureTurnitinDialog extends StatefulWidget {
  const _ConfigureTurnitinDialog();

  @override
  State<_ConfigureTurnitinDialog> createState() => _ConfigureTurnitinDialogState();
}

class _ConfigureTurnitinDialogState extends State<_ConfigureTurnitinDialog> {
  final TextEditingController _apiBaseUrl = TextEditingController(
    text: 'https://app-us.turnitin.com/api/v1',
  );
  final TextEditingController _apiKey = TextEditingController();
  final TextEditingController _integrationName = TextEditingController(text: 'Hackz');
  final TextEditingController _integrationVersion = TextEditingController(text: '1.0.2');

  @override
  void dispose() {
    _apiBaseUrl.dispose();
    _apiKey.dispose();
    _integrationName.dispose();
    _integrationVersion.dispose();
    super.dispose();
  }

  void _save() {
    final String key = _apiKey.text.trim();
    final String base = _apiBaseUrl.text.trim();
    if (base.isEmpty || key.isEmpty) return;
    Navigator.of(context).pop(<String, String>{
      'apiBaseUrl': base,
      'apiKey': key,
      'integrationName': _integrationName.text.trim().isEmpty ? 'Hackz' : _integrationName.text.trim(),
      'integrationVersion':
          _integrationVersion.text.trim().isEmpty ? '1.0.2' : _integrationVersion.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppDialogTemplate(
      width: DialogWidthPreset.wide,
      maxWidth: 560,
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Save securely'),
              ),
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Configure Turnitin',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Credentials are sent once to the Hackz Analysis Service and stored in Google Cloud Secret Manager. '
            'They are never shown again in Hackz.',
            style: TextStyle(fontSize: 12.5, height: 1.45, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiBaseUrl,
            decoration: HackzInputDecoration.decorate(
              labelText: 'Turnitin API base URL',
              hintText: 'https://app-us.turnitin.com/api/v1',
              prefixIcon: Icon(AppIcons.openInNew, size: 18, color: HackzInputDecoration.iconColor),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _apiKey,
            obscureText: true,
            decoration: HackzInputDecoration.decorate(
              labelText: 'API key (TCA secret)',
              hintText: 'Paste the one-time secret from Turnitin Integrations',
              prefixIcon: Icon(AppIcons.key, size: 18, color: HackzInputDecoration.iconColor),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _integrationName,
            decoration: HackzInputDecoration.decorate(
              labelText: 'X-Turnitin-Integration-Name',
              hintText: 'Hackz',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _integrationVersion,
            decoration: HackzInputDecoration.decorate(
              labelText: 'X-Turnitin-Integration-Version',
              hintText: '1.0.2',
            ),
          ),
        ],
      ),
    );
  }
}
