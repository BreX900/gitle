import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitle/git/atoms/commit_dialog.dart';
import 'package:gitle/git/atoms/git_graph_atom.dart';
import 'package:gitle/git/atoms/repositories_drawer_atom.dart';
import 'package:gitle/git/atoms/repository_settings_drawer.dart';
import 'package:gitle/git/atoms/stash_atom.dart';
import 'package:gitle/git/atoms/working_tree_atom.dart';
import 'package:gitle/git/clients/git_extensions.dart';
import 'package:gitle/git/dialogs/remote_url_dialog.dart';
import 'package:gitle/git/dto/git_dto.dart';
import 'package:gitle/git/models/repository_model.dart';
import 'package:gitle/git/providers/git_providers.dart';
import 'package:gitle/git/providers/repositories_providers.dart';
import 'package:mek/mek.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:path/path.dart' as p;

class GitScreen extends ConsumerStatefulWidget {
  const GitScreen({super.key});

  @override
  ConsumerState<GitScreen> createState() => _GitScreenState();
}

class _GitScreenState extends ConsumerState<GitScreen> {
  final _workingTreeKey = GlobalKey<WorkingTreeAtomState>();

  final _referenceNames = FormControlTyped(initialValue: const ISet<String>.empty());

  @override
  void dispose() {
    _referenceNames.dispose();
    super.dispose();
  }

  late final _fetch = ref.mutation(GitProviders.fetch);
  late final _rebaseContinue = ref.mutation(GitProviders.rebaseContinue, onSuccess: (_, message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  });
  late final _rebaseAbort = ref.mutation(GitProviders.rebaseAbort, onSuccess: (_, message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  });
  late final _removeRepository =
      ref.mutation(RepositoriesProviders.remove, onSuccess: (_, message) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Removed repository!'),
    ));
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colors = theme.colorScheme;

    final state = ref.watch(RepositoriesProviders.current);
    final repository = ref.watch(RepositoriesProviders.current.select((state) {
      return state.valueOrNull;
    }));

    final isGitIdle = !ref.watchIsMutating([_fetch, _rebaseContinue]);

    Widget buildRepository(RepositoryModel repository) {
      return MultiSplitView(
        axis: Axis.vertical,
        initialAreas: [
          Area(minimalSize: kMinInteractiveDimension * 2),
          Area(minimalSize: kMinInteractiveDimension)
        ],
        children: [
          MultiSplitView(
            initialAreas: [
              Area(minimalSize: kMinInteractiveDimension * 6),
              Area(minimalSize: kMinInteractiveDimension * 9)
            ],
            children: [
              Material(
                child: WorkingTreeAtom(
                  key: _workingTreeKey,
                  repository: repository,
                ),
              ),
              Material(
                child: DefaultTabController(
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
                              gitDir: repository.gitDir,
                              filePaths: () => _workingTreeKey.currentState!.selection
                                  .expand((e) => e.paths)
                                  .toList(),
                            ),
                            StashAtom(
                              repository: repository,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
          Material(
            child: GitGraphAtom(repository: repository),
          ),
        ],
      );
    }

    Widget? branchesDropdown;
    if (repository != null) {
      branchesDropdown = ReactivePopupMenuButton(
        formControl: _referenceNames,
        // constraints: const BoxConstraints.tightFor(width: 384.0),
        // padding: EdgeInsets.zero,
        decoration: const InputDecoration(
          isCollapsed: true,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8.0),
        ),
        itemBuilder: (field) {
          final selection = field.value ?? const ISet.empty();
          return repository.references.where((e) => e.isLocal || e.isRemote).map((e) {
            return CheckedPopupMenuItem(
              value: e.name,
              checked: selection.contains(e.name),
              child: Text(e.name),
            );
          }).toList();
        },
        builder: (field) {
          final selection = field.value ?? const ISet.empty();
          return ConstrainedBox(
            constraints: const BoxConstraints.tightFor(height: 48.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Branches: ${selection.isEmpty ? 'Show All' : selection.join(', ')}',
                maxLines: 2,
              ),
            ),
          );
        },
      );
    }

    final isLoading = ref.watch(RepositoriesProviders.current.select((value) => value.isLoading));

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
          if (repository != null &&
              repository.workingTree
                  .any((e) => e.status.contains(FileStatus.updatedAndUnmerged))) ...[
            IconButton(
              color: colors.secondary,
              tooltip: '-c core.editor=true rebase --continue',
              onPressed: isGitIdle ? () => _rebaseContinue(repository.gitDir) : null,
              icon: const Icon(Icons.next_plan_outlined),
            ),
            IconButton(
              color: colors.secondary,
              tooltip: 'rebase --abort',
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
              onPressed: () async => showTypedDialog(
                context: context,
                builder: (context) => RemoteUrlDialog(repository: repository),
              ),
              icon: const Icon(Icons.cloud),
            ),
          if (repository != null)
            IconButton(
              tooltip: 'fetch --all',
              onPressed: isGitIdle
                  ? () => _fetch((
                        gitDir: repository.gitDir,
                        prune: false,
                        remoteBranchName: null,
                        localBranch: null,
                      ))
                  : null,
              icon: const Icon(Icons.sync_outlined),
            ),
          if (repository != null)
            IconButton(
              tooltip: 'fetch --all --prune',
              onPressed: isGitIdle
                  ? () => _fetch((
                        gitDir: repository.gitDir,
                        prune: true,
                        remoteBranchName: null,
                        localBranch: null,
                      ))
                  : null,
              icon: const Icon(Icons.cloud_sync_outlined),
            ),
          const EndDrawerButton(),
        ],
        flexibleSpace: LinearProgressIndicatorBar(isHidden: isGitIdle && !isLoading),
      ),
      drawer: const RepositoriesDrawerAtom(),
      endDrawer: repository != null ? RepositorySettingsDrawer(repository: repository) : null,
      body: state.whenOrNull(
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
          return DataBuilders.buildError(context, error);
        },
        data: (repository) {
          if (repository == null) {
            return Builder(builder: (context) {
              return InfoView(
                onTap: () => Scaffold.of(context).openDrawer(),
                title: const Text('Select repository'),
              );
            });
          }
          return buildRepository(repository);
        },
      ),
    );
  }
}

// Widget buildBranches(RepositoryDto repository) {
//   return ListView(
//     primary: false,
//     children: repository.commits.map((commit) {
//       return ListTile(
//         onTap: () async {
//           final gitDir = await GitDir.fromExisting(repository.path);
//           gitDir.checkout(commit.reference);
//           ref.invalidate(RepositoriesProviders.current);
//         },
//         title: Text(commit.reference),
//         subtitle: Text('${commit.reference == repository.currentBranch.reference}'),
//         trailing: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             IconButton(
//               onPressed: () {},
//               tooltip: 'Rebase Develop',
//               icon: const Icon(Icons.arrow_downward),
//             ),
//             IconButton(
//               onPressed: () {},
//               tooltip: 'Rebase Develop',
//               icon: const Icon(Icons.arrow_downward),
//             ),
//           ],
//         ),
//       );
//     }).toList(),
//   );
// }
