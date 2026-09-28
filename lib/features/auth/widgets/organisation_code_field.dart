import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/firebase/organisation_code.dart';
import '../../../core/theme/auth_theme.dart';

class OrganisationCodeInputFormatter extends TextInputFormatter {
  const OrganisationCodeInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String formatted = OrganisationCode.formatInput(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class OrganisationCodeField extends StatelessWidget {
  const OrganisationCodeField({
    super.key,
    required this.controller,
    this.focusNode,
    this.onSubmitted,
    this.autofocus = false,
    this.textInputAction = TextInputAction.done,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    const TextStyle textStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: Color(0xFF202658),
    );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      textCapitalization: TextCapitalization.characters,
      keyboardType: TextInputType.text,
      textInputAction: textInputAction,
      autocorrect: false,
      enableSuggestions: false,
      style: textStyle,
      inputFormatters: const <TextInputFormatter>[
        OrganisationCodeInputFormatter(),
      ],
      decoration: AuthTheme.filledField(
        hintText: 'HKZ-XXXXXX',
        prefixIcon: const Icon(Icons.apartment_outlined),
      ).copyWith(
        hintStyle: textStyle.copyWith(
          color: const Color(0xFF7A7FA3),
          fontWeight: FontWeight.w400,
          letterSpacing: 1.0,
        ),
      ),
      onSubmitted: onSubmitted,
    );
  }
}
