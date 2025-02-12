import 'package:flutter/material.dart';

class ShaText extends StatelessWidget {
  final String value;
  final TextStyle? style;

  static String resolve(String value) => value.substring(0, 8);

  const ShaText(this.value, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: value,
      child: Text(
        resolve(value),
        style: style,
      ),
    );
  }
}
