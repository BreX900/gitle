import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/features/code_magic/widgets/code_magic_repository_drawer_view.dart';
import 'package:gitle/features/repositories/repositories_providers.dart';
import 'package:gitle/features/repositories/repository_model.dart';
import 'package:gitle/shared/default_tab_controller_storage.dart';
import 'package:mek/mek.dart';

class RepositoryDrawer extends ConsumerStatefulWidget {
  final RepositoryModel repository;

  const RepositoryDrawer({super.key, required this.repository});

  @override
  ConsumerState<RepositoryDrawer> createState() => _RepositoryDrawerState();
}

class _RepositoryDrawerState extends ConsumerState<RepositoryDrawer> {
  late final _mutation = MutationController(ref);

  @override
  void dispose() {
    _mutation.dispose();
    super.dispose();
  }

  void _toggleBranchProtection(bool isEnabled) {
    _mutation(
      (ref) async =>
          await RepositoriesProviders.toggleBranchesProtection(ref, isEnabled: isEnabled),
      onError: (error, stackTrace) => AppUtils.showErrorSnackBar(context, error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIdle = !ref.watch(_mutation.provider.isPending);
    final tabs = <(Widget, Widget)>[
      (
        const Tab(text: 'CodeMagic'),
        CodeMagicRepositoryDrawerView(config: widget.repository.config.codeMagic),
      ),
    ];

    return DefaultTabController(
      length: tabs.length,
      initialIndex: DefaultTabControllerStorage.initialIndexOf(context),
      child: DefaultTabControllerStorage(
        child: Drawer(
          key: const PageStorageKey(RepositoryDrawer),
          width: 384.0,
          child: Column(
            children: [
              SwitchListTile(
                value: widget.repository.config.hasBranchProtection,
                onChanged: isIdle ? _toggleBranchProtection : null,
                title: const Text('Enable branches protection?'),
                subtitle: const Text('master, develop, main'),
              ),

              const Divider(),

              TabBar(tabs: tabs.map((e) => e.$1).toList()),
              Expanded(child: TabBarView(children: tabs.map((e) => e.$2).toList())),
            ],
          ),
        ),
      ),
    );
  }
}
