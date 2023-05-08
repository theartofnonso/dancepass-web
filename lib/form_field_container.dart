import 'package:flutter/material.dart';

class FormFieldContainer extends StatelessWidget {

  final Widget child;

  final double width;

  const FormFieldContainer({Key? key, required this.child, required this.width}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.grey.shade200,
      ),
      padding: const EdgeInsets.all(8),
      width: width,
      child: child,
    );
  }
}
