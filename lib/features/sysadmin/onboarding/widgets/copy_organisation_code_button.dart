import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/ui/buttons/hover_icon_action_button.dart';

class CopyOrganisationCodeButton extends StatefulWidget {
  const CopyOrganisationCodeButton({super.key, required this.code});

  final String code;

  @override
  State<CopyOrganisationCodeButton> createState() => _CopyOrganisationCodeButtonState();
}

class _CopyOrganisationCodeButtonState extends State<CopyOrganisationCodeButton> {
  static const Duration _copiedDuration = Duration(seconds: 2);

  bool _copied = false;
  Timer? _revertTimer;

  @override
  void dispose() {
    _revertTimer?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    final String code = widget.code.trim();
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    _revertTimer?.cancel();
    setState(() => _copied = true);
    _revertTimer = Timer(_copiedDuration, () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return HoverIconActionButton(
      icon: _copied ? AppIcons.copied : AppIcons.copy,
      tooltip: _copied ? 'Copied' : 'Copy organisation code',
      iconColor: _copied ? const Color(0xFF047857) : null,
      onTap: _copy,
    );
  }
}
