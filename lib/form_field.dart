import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CTextFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType type;
  final Function? onChanged;
  final Function? validator;
  final bool shouldValidate;
  final Widget? prefixIcon;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;

  const CTextFormField({Key? key, required this.controller, required this.type, this.onChanged, required this.label, this.inputFormatters, this.validator, this.shouldValidate = true, this.prefixIcon, this.textCapitalization = TextCapitalization.none}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: textCapitalization,
      keyboardType: type,
      onChanged: (value) => onChanged != null ? onChanged!(value) : null,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: prefixIcon
      ),
      validator: (value) {
        if(shouldValidate) {
          if (value == null || value.isEmpty) {
            return '$label has not been provided';
          }
          if (validator != null) {
            return validator!();
          }
        }
        return null;
      },
    );
  }
}
