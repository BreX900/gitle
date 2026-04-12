import 'package:flutter/material.dart';

class InfoBox extends StatelessWidget {
  final List<Widget> children;

  const InfoBox({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(children: children);
  }
}

class InfoBoxTile extends StatelessWidget {
  final Widget label;
  final Widget child;

  const InfoBoxTile({super.key, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(spacing: 8.0, children: [label, child]);
  }
}
