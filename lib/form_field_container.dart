import 'package:flutter/material.dart';

class FormFieldContainer extends StatelessWidget {

  final Widget child;

  const FormFieldContainer({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.grey.shade100,
          width: 2.0,
        ),
      ),
      child: child,
    );
  }
}
