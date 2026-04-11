import 'package:flutter/material.dart';
import 'package:mek/mek.dart';
import 'package:multi_split_view/multi_split_view.dart';

class DashboardLayout extends StatefulWidget {
  final Widget left;
  final Widget right;
  final Widget bottom;

  const DashboardLayout({required this.left, required this.right, required this.bottom});

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  late final _topArea = Area(min: 0.5, flex: 1, builder: _buildTopArea);
  late final _bottomArea = Area(min: 0.5, flex: 1, builder: _buildBottomArea);

  late final _leftArea = Area(min: 0.5, flex: 1, builder: _buildLeftArea);
  late final _rightArea = Area(min: 0.5, flex: 1, builder: _buildRightArea);

  @override
  void dispose() {
    _topArea.dispose();
    _bottomArea.dispose();
    _leftArea.dispose();
    _rightArea.dispose();
    super.dispose();
  }

  Widget _buildTopArea(BuildContext context, Area area) =>
      MultiSplitView(initialAreas: [_leftArea, _rightArea]);

  Widget _buildBottomArea(BuildContext context, Area area) => Surface(child: widget.bottom);

  Widget _buildLeftArea(BuildContext context, Area area) => Surface(child: widget.left);

  Widget _buildRightArea(BuildContext context, Area area) => Surface(child: widget.right);

  @override
  Widget build(BuildContext context) =>
      MultiSplitView(axis: Axis.vertical, initialAreas: [_topArea, _bottomArea]);
}
