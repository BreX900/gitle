import 'package:flutter/material.dart';

class ShaText extends StatelessWidget {
  final String value;
  final TextStyle? style;

  const ShaText(this.value, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: value,
      child: Text(
        value.substring(0, 8),
        style: style,
      ),
    );
  }
}
