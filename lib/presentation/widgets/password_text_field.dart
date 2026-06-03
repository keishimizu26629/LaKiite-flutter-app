import 'package:flutter/material.dart';

class PasswordTextField extends StatelessWidget {
  const PasswordTextField({
    required this.controller,
    required this.labelText,
    required this.obscureText,
    required this.onToggleVisibility,
    this.textInputAction,
    this.autofillHints = const [AutofillHints.password],
    super.key,
  });

  final TextEditingController controller;
  final String labelText;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: obscureText ? '$labelTextを表示' : '$labelTextを非表示',
          icon: Icon(
            obscureText ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: onToggleVisibility,
        ),
      ),
      obscureText: obscureText,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
    );
  }
}
