import 'package:flutter/material.dart';

class CTextFormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType type;
  final Function? onChanged;

  const CTextFormField({Key? key, required this.controller, required this.type, this.onChanged, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        controller: controller,
        keyboardType: type,
        onChanged: (value) => onChanged != null ? onChanged!(value) : null,
        decoration: InputDecoration(
          hintText: label,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label has not been provided';
          }
          return null;
        },
    );
  }
}
