import 'package:flutter/material.dart';

class DefaultTabControllerStorage extends StatefulWidget {
  final Widget child;

  const DefaultTabControllerStorage({super.key, required this.child});

  static int initialIndexOf(BuildContext context) =>
      PageStorage.of(context).readState(context) ?? 0;

  @override
  State<DefaultTabControllerStorage> createState() => _DefaultTabControllerStorageState();
}

class _DefaultTabControllerStorageState extends State<DefaultTabControllerStorage> {
  TabController? _controller;
  PageStorageBucket? _pageStorageBucket;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final controller = DefaultTabController.of(context);
    if (controller != _controller) {
      _controller?.removeListener(_onChange);
      _controller = controller;
      _controller?.addListener(_onChange);
    }

    final pageStorageBucket = PageStorage.of(context);
    if (_pageStorageBucket != pageStorageBucket || controller != _controller) {
      _pageStorageBucket?.writeState(context, null);
      _pageStorageBucket = pageStorageBucket;
      _pageStorageBucket?.writeState(context, _controller?.index ?? 0);
    }
  }

  void _onChange() {
    _pageStorageBucket!.writeState(context, _controller!.index);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
