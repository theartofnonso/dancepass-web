import 'package:flutter/material.dart';

class CTextFormField extends StatelessWidget {

  final String label;
  final TextEditingController controller;
  final TextInputType type;
  final double width;
  final Function? onChanged;

  const CTextFormField({Key? key, required this.controller, required this.width, required this.type, this.onChanged, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(3)),
        ),
        onChanged: (value) => onChanged != null ? onChanged!(value) : null,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label has not been provided';
          }
          return null;
        },
      ),
    );
  }
}
