import 'package:flutter/material.dart';
import 'package:gitle/git/dto/repository_dto.dart';
import 'package:gitle/git/providers/dashboard_providers.dart';
import 'package:gitle/git/providers/repositories_providers.dart';
import 'package:gitle/git/widgets/input_dialog.dart';
import 'package:mek/mek.dart';
import 'package:path/path.dart' as path_;

// Tab height + indicator height
const double _kTabHeight = 46.0 + 2.0;

class RepositoriesTabBarScene extends StatelessWidget implements PreferredSizeWidget {
  final DashboardConfigDto config;

  const RepositoriesTabBarScene({super.key, required this.config});

  @override
  Size get preferredSize => const Size.fromHeight(_kTabHeight * 2);

  Future<void> _showGroupUpsertDialog(BuildContext context, String? uid) async {
    final groupUid = await showDialog<String?>(
      context: context,
      builder: (context) =>
          InputDialog(title: Text('${uid == null ? 'Create' : 'Update'} group'), value: uid ?? ''),
    );
    if (groupUid == null) return;

    await DashboardProviders.upsertGroup(groupUid, oldUid: uid);
  }

  Widget _buildTab<T extends Object>({
    required T value,
    required void Function(T destination, {required bool after}) onMove,
    void Function()? onUpdate,
    required void Function() onDelete,
    required String text,
  }) {
    final tab = Tab(text: text);

    return PreferredSize(
      key: ObjectKey(value),
      preferredSize: tab.preferredSize,
      child: DraggableTarget<T>(
        data: value,
        onAccepted: (position, data) =>
            onMove(data, after: position == DraggableTargetDestination.after),
        direction: Axis.horizontal,
        child: PopupMenuArea(
          items: [
            // PopupMenuItemTile(
            //   onTap: () async {
            //     // Create a new window
            //     final controller = await WindowController.create(
            //       WindowConfiguration(
            //         hiddenAtLaunch: false,
            //         arguments: 'YOUR_WINDOW_ARGUMENTS_HERE',
            //       ),
            //     );
            //     await controller.show();
            //   },
            //   leading: const Icon(Icons.open_in_new),
            //   title: const Text('Open in new window'),
            // ),
            if (onUpdate != null)
              PopupMenuItemTile(
                onTap: onUpdate,
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
              ),
            PopupMenuItemTile(
              onTap: onDelete,
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
            ),
          ],
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0), child: tab),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: preferredSize,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ControlledTabBar(
                  index: config.groupIndex,
                  onTap: (index) => DashboardProviders.selectGroup(config.groups[index].uid),
                  tabs: config.groups.map((group) {
                    final groupUid = group.uid;

                    if (groupUid == null) {
                      return const Tab(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Icon(Icons.home),
                        ),
                      );
                    }

                    return _buildTab<String>(
                      value: groupUid,
                      onMove: (data, {required after}) =>
                          DashboardProviders.moveGroup(data, groupUid, after: after),
                      onUpdate: () => _showGroupUpsertDialog(context, groupUid),
                      onDelete: () => DashboardProviders.deleteGroup(groupUid),
                      text: groupUid,
                    );
                  }).toList(),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showGroupUpsertDialog(context, null),
                iconAlignment: .end,
                icon: const Icon(Icons.add),
                label: const Text('Create Group'),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: .end,
            children: [
              if (config.group.items.isNotEmpty)
                Expanded(
                  child: _ControlledTabBar(
                    index: config.group.itemIndex ?? 0,
                    onTap: (index) => DashboardProviders.selectItem(config.group.items[index]),
                    padding: const EdgeInsets.only(left: 56.0),
                    tabs: config.group.items.map((itemUid) {
                      return _buildTab<String>(
                        value: itemUid,
                        onMove: (data, {required after}) =>
                            DashboardProviders.moveItem(data, itemUid, after: after),
                        onDelete: () => DashboardProviders.deleteItem(itemUid),
                        text: path_.basename(itemUid),
                      );
                    }).toList(),
                  ),
                ),
              TextButton.icon(
                onPressed: () => RepositoriesProviders.add(null, null),
                iconAlignment: .end,
                icon: const Icon(Icons.add),
                label: const Text('Open Repository'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlledTabBar extends StatefulWidget {
  final int index;
  final ValueChanged<int> onTap;
  final EdgeInsetsGeometry? padding;
  final List<Widget> tabs;

  const _ControlledTabBar({
    required this.index,
    required this.onTap,
    this.padding,
    required this.tabs,
  });

  @override
  State<_ControlledTabBar> createState() => _ControlledTabBarState();
}

class _ControlledTabBarState extends State<_ControlledTabBar> with TickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      vsync: this,
      length: widget.tabs.length,
      initialIndex: widget.index,
    );
  }

  @override
  void didUpdateWidget(covariant _ControlledTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tabs.length != oldWidget.tabs.length) {
      _controller.dispose();
      _controller = TabController(
        vsync: this,
        length: widget.tabs.length,
        initialIndex: widget.index,
      );
    }
    final previousIndex = oldWidget.index;
    final index = widget.index;
    if (index != previousIndex && index != _controller.index) {
      _controller.animateTo(index);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: _controller,
      tabAlignment: TabAlignment.start,
      isScrollable: true,
      onTap: widget.onTap,
      padding: widget.padding,
      labelPadding: .zero,
      tabs: widget.tabs,
    );
  }
}
