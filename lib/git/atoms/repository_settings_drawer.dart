import 'package:flutter/material.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/features/code_magic/code_magic_builds_drawer_view.dart';
import 'package:gitle/features/git_hub/git_hub_notifications_drawer_view.dart';
import 'package:gitle/features/repositories/repositories_providers.dart';
import 'package:gitle/features/repositories/repository_model.dart';
import 'package:mek/mek.dart';

class RepositorySettingsDrawer extends SourceConsumerStatefulWidget {
  final RepositoryModel repository;

  const RepositorySettingsDrawer({super.key, required this.repository});

  @override
  SourceConsumerState<RepositorySettingsDrawer> createState() => _RepositorySettingsDrawerState();
}

class _RepositorySettingsDrawerState extends SourceConsumerState<RepositorySettingsDrawer> {
  late final _toggleBranchProtection = ref.mutation((ref, bool isEnabled) async {
    await RepositoriesProviders.toggleBranchesProtection(ref, isEnabled: isEnabled);
  }, onError: (_, error) => AppUtils.showErrorSnackBar(context, error));

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Drawer(
        width: 384.0,
        child: Column(
          children: [
            SwitchListTile(
              value: widget.repository.config.hasBranchProtection,
              onChanged: _toggleBranchProtection,
              title: const Text('Enable branches protection?'),
              subtitle: const Text('master, develop, main'),
            ),

            const Divider(),

            const TabBar(
              tabs: [
                Tab(text: 'GitHub'),
                Tab(text: 'CodeMagic'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  const GitHubNotificationsDrawerView(),
                  CodeMagicBuildsDrawerView(config: widget.repository.config.codeMagic),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
