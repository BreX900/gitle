import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/git/atoms/commit_dialog.dart';
import 'package:gitle/git/atoms/git_graph_atom.dart';
import 'package:gitle/git/atoms/repositories_drawer_atom.dart';
import 'package:gitle/git/atoms/repository_settings_drawer.dart';
import 'package:gitle/git/atoms/stash_atom.dart';
import 'package:gitle/git/atoms/working_tree_atom.dart';
import 'package:gitle/git/clients/git_extensions.dart';
import 'package:gitle/git/dialogs/remote_url_dialog.dart';
import 'package:gitle/git/dto/repository_dto.dart';
import 'package:gitle/git/models/repository_model.dart';
import 'package:gitle/git/providers/dashboard_providers.dart';
import 'package:gitle/git/providers/git_providers.dart';
import 'package:gitle/git/providers/repositories_providers.dart';
import 'package:gitle/git/widgets/dashboard_layout.dart';
import 'package:gitle/git/widgets/repositories_tab_bar_scene.dart';
import 'package:mek/mek.dart';
import 'package:path/path.dart' as p;

final _screenProvider = FutureProvider.autoDispose((ref) {
  return (
    ref.watch(DashboardProviders.config).requireValue,
    ref.watch(RepositoriesProviders.current).requireValue,
  );
});

class GitScreen extends SourceConsumerStatefulWidget {
  const GitScreen({super.key});

  @override
  SourceConsumerState<GitScreen> createState() => _GitScreenState();
}

class _GitScreenState extends SourceConsumerState<GitScreen> {
  final _referenceNames = FormControlTyped(initialValue: const ISet<String>.empty());

  @override
  void dispose() {
    _referenceNames.dispose();
    super.dispose();
  }

  void _refresh() => ref.invalidateWithAncestors(RepositoriesProviders.current);

  late final _fetch = ref.mutation((ref, (GitDir, {bool prune}) __) async {
    final (gitDir, :prune) = __;
    await GitProviders.fetch(ref, gitDir, prune: prune);
  }, onError: (_, error) => AppUtils.showErrorSnackBar(context, error));

  late final _rebaseContinue = ref.mutation(
    GitProviders.rebaseContinue,
    onError: (_, error) => AppUtils.showErrorSnackBar(context, error),
    onSuccess: (_, message) =>
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))),
  );

  late final _rebaseAbort = ref.mutation(
    GitProviders.rebaseAbort,
    onError: (_, error) => AppUtils.showErrorSnackBar(context, error),
    onSuccess: (_, message) =>
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))),
  );

  late final _removeRepository = ref.mutation(
    RepositoriesProviders.remove,
    onError: (_, error) => AppUtils.showErrorSnackBar(context, error),
    onSuccess: (_, message) => ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Removed repository!'))),
  );

  Widget buildRepository({
    required DashboardConfigDto config,
    required RepositoryModel? repository,
  }) {
    if (repository == null) {
      return Builder(
        builder: (context) {
          return InfoView(
            onTap: () => Scaffold.of(context).openDrawer(),
            title: const Text('Select repository'),
          );
        },
      );
    }
    return _GitView(key: ValueKey(repository.path), repository: repository);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = theme.colorScheme;

    final state = ref.watch(_screenProvider);
    final isLoading = state.isLoading;
    final repository = state.value?.$2;

    final isGitIdle = !ref.watchIsMutating([_fetch, _rebaseContinue]);

    Widget? branchesDropdown;
    if (repository != null) {
      branchesDropdown = ReactivePopupMenuButton(
        formControl: _referenceNames,
        constraints: const BoxConstraints.tightFor(width: 384.0),
        decoration: const InputDecoration(
          isCollapsed: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(12.0),
          hintText: 'Branches...',
        ),
        itemBuilder: (field) {
          return repository.references.where((e) => e.isLocal || e.isRemote).map((e) {
            return CheckedPopupMenuItem(
              value: e.name,
              checked: field.value.contains(e.name),
              child: Text(e.name),
            );
          }).toList();
        },
        builder: (field) {
          return ConstrainedBox(
            constraints: const BoxConstraints.tightFor(height: 48.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Branches: ${field.value.isEmpty ? 'Show All' : field.value.join(', ')}',
                maxLines: 2,
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        titleTextStyle: const TextStyle(inherit: false),
        leadingWidth: 384.0,
        leading: Row(
          children: [
            const DrawerButton(),
            Text(
              repository != null ? p.basename(repository.gitDir.path) : 'Repositories',
              style: textTheme.titleLarge,
            ),
          ],
        ),
        title: branchesDropdown,
        actions: [
          if (repository != null && repository.isRebaseInProgress) ...[
            IconButton(
              color: colors.secondary,
              tooltip: 'git -c core.editor=true rebase --continue',
              onPressed: isGitIdle ? () => _rebaseContinue(repository.gitDir) : null,
              icon: const Icon(Icons.next_plan_outlined),
            ),
            IconButton(
              color: colors.secondary,
              tooltip: 'git rebase --abort',
              onPressed: isGitIdle ? () => _rebaseAbort(repository.gitDir) : null,
              icon: const Icon(Icons.settings_backup_restore),
            ),
          ],
          // if (repository != null)
          //   IconButton(
          //     tooltip: 'commit --message=<>',
          //     onPressed: !repository.isWorkingTreeClean
          //         ? () => unawaited(showDialog(
          //               context: context,
          //               barrierDismissible: false,
          //               builder: (context) => CommitDialog(gitDir: repository.gitDir),
          //             ))
          //         : null,
          //     icon: const Icon(Icons.check),
          //   ),
          if (repository != null)
            IconButton(
              onPressed: () => showTypedDialog(
                context: context,
                builder: (context) => RemoteUrlDialog(repository: repository),
              ),
              icon: const Icon(Icons.cloud),
            ),
          if (repository != null)
            IconButton(
              tooltip: 'fetch  --tags --all',
              onPressed: isGitIdle ? () => _fetch((repository.gitDir, prune: false)) : null,
              icon: const Icon(Icons.sync_outlined),
            ),
          if (repository != null)
            IconButton(
              tooltip: 'fetch  --tags --all --prune',
              onPressed: isGitIdle ? () => _fetch((repository.gitDir, prune: true)) : null,
              icon: const Icon(Icons.cloud_sync_outlined),
            ),
          const EndDrawerButton(),
        ],
        bottom: state.whenOrNull(
          skipLoadingOnRefresh: true,
          skipLoadingOnReload: true,
          data: (data) => RepositoriesTabBarScene(config: data.$1),
        ),
        flexibleSpace: FlexibleLinearProgressBar(visible: !isGitIdle || isLoading),
      ),
      drawer: const RepositoriesDrawerAtom(),
      endDrawer: repository != null ? RepositorySettingsDrawer(repository: repository) : null,
      body: state.whenOrNull(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        error: (error, _) {
          if (error is InvalidGitDirFailure) {
            return InfoView(
              title: const Text('Invalid repository!'),
              description: Text(error.path),
              actions: [
                OutlinedButton.icon(
                  onPressed: () => _removeRepository(error.path),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove'),
                ),
              ],
            );
          }
          return ErrorView(error: error, onRefresh: _refresh);
        },
        data: (data) => buildRepository(config: data.$1, repository: data.$2),
      ),
    );
  }
}

class _GitView extends StatefulWidget {
  final RepositoryModel repository;

  const _GitView({super.key, required this.repository});

  @override
  State<_GitView> createState() => _GitViewState();
}

class _GitViewState extends State<_GitView> {
  final _workingTreeKey = GlobalKey<WorkingTreeAtomState>();

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      left: WorkingTreeAtom(key: _workingTreeKey, repository: widget.repository),
      right: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Commit'),
                Tab(text: 'Stash'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  FormCommitAtom(
                    gitDir: widget.repository.gitDir,
                    filePaths: () =>
                        _workingTreeKey.currentState!.selection.expand((e) => e.paths).toList(),
                  ),
                  StashAtom(repository: widget.repository),
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: GitGraphAtom(repository: widget.repository),
    );
  }
}
