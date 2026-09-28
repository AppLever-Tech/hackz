import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneNumberField extends StatelessWidget {
  const PhoneNumberField({
    super.key,
    required this.controller,
    this.hintText = 'Enter phone number',
    this.decoration,
    this.onSubmitted,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction = TextInputAction.done,
  });

  final TextEditingController controller;
  final String hintText;
  final InputDecoration? decoration;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final InputDecoration baseDecoration = decoration ?? const InputDecoration();
    const TextStyle textStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Color(0xFF202658),
    );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      keyboardType: TextInputType.phone,
      textInputAction: textInputAction,
      style: textStyle,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: baseDecoration.copyWith(
        hintText: hintText,
        hintStyle: textStyle.copyWith(
          color: const Color(0xFF7A7FA3),
          fontWeight: FontWeight.w400,
        ),
        prefixText: '+91  ',
        prefixStyle: textStyle,
      ),
      onSubmitted: onSubmitted,
    );
  }
}
