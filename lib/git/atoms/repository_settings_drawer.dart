import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/git/models/repository_model.dart';
import 'package:gitle/git/providers/repositories_providers.dart';
import 'package:mek/mek.dart';

class RepositorySettingsDrawer extends ConsumerStatefulWidget {
  final RepositoryModel repository;

  const RepositorySettingsDrawer({
    super.key,
    required this.repository,
  });

  @override
  ConsumerState<RepositorySettingsDrawer> createState() => _RepositorySettingsDrawerState();
}

class _RepositorySettingsDrawerState extends ConsumerState<RepositorySettingsDrawer> {
  late final _toggleBranchProtection = ref.mutation((ref, bool isEnabled) async {
    await RepositoriesProviders.toggleBranchesProtection(ref, isEnabled: isEnabled);
  }, onError: (_, error) {
    AppUtils.showErrorSnackBar(context, error);
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          SwitchListTile(
            value: widget.repository.settings.hasBranchProtection,
            onChanged: _toggleBranchProtection,
            title: const Text('Enable branches protection?'),
            subtitle: const Text('master, develop, main'),
          ),
        ],
      ),
    );
  }
}
