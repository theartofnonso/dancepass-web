import 'package:flutter/material.dart';

import 'form_field_container.dart';

class DateAndTime extends StatelessWidget {
  final Function onSelect;
  final String label;

  const DateAndTime({Key? key, required this.onSelect, required this.label}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
          onTap: () => onSelect(),
          child: FormFieldContainer(
              child: Row(
            children: [
              const Icon(Icons.access_time_outlined, color: Colors.grey,),
              const Spacer(),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          )),

      ),
    );
  }
}
