import 'package:flutter/material.dart';
import 'package:gitle/features/code_magic/widgets/code_magic_drawer_view.dart';
import 'package:gitle/features/git/screens/git_settings_screen.dart';
import 'package:gitle/features/git_hub/widgets/git_hub_notifications_drawer_view.dart';
import 'package:gitle/features/repositories/repository_entity.dart';
import 'package:gitle/features/repositories/widgets/repositories_drawer_view.dart';
import 'package:gitle/shared/default_tab_controller_storage.dart';
import 'package:mek/mek.dart';

class DashboardDrawer extends StatelessWidget {
  final RepositoryConfigEntity? config;

  const DashboardDrawer({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final tabs = <(Widget, Widget)>[
      const (Tab(text: 'Repositories'), RepositoriesDrawerView()),

      const (Tab(text: 'GitHub'), GitHubNotificationsDrawerView()),

      if (config?.codeMagic case final config?)
        (const Tab(text: 'CodeMagic'), CodeMagicDrawerView(config: config)),
    ];

    return DefaultTabController(
      length: tabs.length,
      initialIndex: DefaultTabControllerStorage.initialIndexOf(context),
      child: DefaultTabControllerStorage(
        child: Drawer(
          key: const PageStorageKey(DashboardDrawer),
          width: 512.0,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  spacing: 8.0,
                  children: [
                    IconButton(
                      onPressed: () => context.nav.popAndPush(const GitSettingsScreen()),
                      icon: const Icon(Icons.settings),
                    ),
                    Expanded(
                      child: TabBar(
                        onTap: (index) =>
                            SharedAppData.setValue(context, '$DashboardDrawer', index),
                        tabs: tabs.map((e) => e.$1).toList(),
                      ),
                    ),
                    const CloseButton(),
                  ],
                ),
              ),
              Expanded(child: TabBarView(children: tabs.map((e) => e.$2).toList())),
            ],
          ),
        ),
      ),
    );
  }
}
