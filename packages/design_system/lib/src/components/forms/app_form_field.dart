import 'package:flutter/material.dart';

/// The single themed text-input shape every form in the app uses (TIS §3)
/// — wraps [TextFormField] with the shared [InputDecorationTheme] instead
/// of each dialog styling its own [TextField].
final class AppFormField extends StatelessWidget {
  const AppFormField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.keyboardType,
    this.validator,
    this.autofocus = false,
    this.errorText,
    this.onChanged,
  });

  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool autofocus;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      autofocus: autofocus,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        errorText: errorText,
      ),
    );
  }
}
