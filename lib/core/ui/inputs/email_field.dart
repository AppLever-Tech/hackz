import 'package:flutter/material.dart';

class EmailField extends StatelessWidget {
  const EmailField({
    super.key,
    required this.controller,
    this.hintText = 'Email Address',
    this.decoration,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final InputDecoration? decoration;
  final ValueChanged<String>? onSubmitted;

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
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: textStyle,
      decoration: baseDecoration.copyWith(
        hintText: hintText,
        hintStyle: textStyle.copyWith(
          color: const Color(0xFF7A7FA3),
          fontWeight: FontWeight.w400,
        ),
      ),
      onSubmitted: onSubmitted,
    );
  }
}
