import 'dart:async';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitle/common/utils.dart';
import 'package:gitle/git/git_logs_screen.dart';
import 'package:gitle/git/git_settings_screen.dart';
import 'package:gitle/git/providers/repositories_providers.dart';
import 'package:mek/mek.dart';
import 'package:path/path.dart' as p;

class RepositoriesDrawerAtom extends ConsumerStatefulWidget {
  const RepositoriesDrawerAtom({super.key});

  @override
  ConsumerState<RepositoriesDrawerAtom> createState() => _RepositoriesDrawerAtomState();
}

class _RepositoriesDrawerAtomState extends ConsumerState<RepositoriesDrawerAtom> {
  late final _addRepository = ref.mutation(RepositoriesProviders.add);
  late final _removeRepository = ref.mutation(RepositoriesProviders.remove);

  Future<void> _selectRepository(String repositoryPath) async {
    Scaffold.of(context).closeDrawer();
    await RepositoriesProviders.select(repositoryPath);
  }

  Widget _buildRepositories(IList<String> repositories) {
    final isIdle = !ref.watchIsMutating([_addRepository, _removeRepository]);
    final repository = ref.watch(RepositoriesProviders.current.select((state) {
      return state.valueOrNull?.gitDir.path;
    }));

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return ListView.builder(
      key: const PageStorageKey<String>('repositories'),
      primary: false,
      itemCount: repositories.length,
      itemBuilder: (context, index) {
        final prevRepositoryPath = index > 0 ? repositories[index - 1] : null;
        final repositoryPath = repositories[index];

        final child = ListTile(
          selected: repository == repositoryPath,
          onTap: isIdle ? () => unawaited(_selectRepository(repositoryPath)) : null,
          leading: const Icon(Icons.archive_outlined),
          title: Text(p.basename(repositoryPath)),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: isIdle ? () => _removeRepository(repositoryPath) : null,
                child: const ListTile(
                  title: Text('Delete'),
                  trailing: Icon(Icons.delete_outline),
                ),
              )
            ],
          ),
        );

        if (prevRepositoryPath != null &&
            p.dirname(prevRepositoryPath) == p.dirname(repositoryPath)) return child;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (prevRepositoryPath != null) const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(Utils.removeHomePath(p.dirname(repositoryPath)),
                  style: textTheme.titleMedium),
            ),
            child,
          ],
        );
      },
    );
  }

  Widget _buildContent(IList<String> repositories) {
    final isIdle = !ref.watchIsMutating([_addRepository, _removeRepository]);

    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: double.infinity,
            minHeight: kToolbarHeight,
          ),
          child: const CloseButton(),
        ),
        Expanded(
          child: _buildRepositories(repositories),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Logs',
              onPressed: () {
                Scaffold.of(context).closeDrawer();
                unawaited(context.nav.push(const GitLogsScreen()));
              },
              icon: const Icon(Icons.bug_report_outlined),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton(
                onPressed: isIdle ? () => _addRepository(null) : null,
                child: const Icon(Icons.add),
              ),
            ),
            IconButton(
              onPressed: () {
                Scaffold.of(context).closeDrawer();
                unawaited(context.nav.push(const GitSettingsScreen()));
              },
              icon: const Icon(Icons.settings),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final repositoriesState = ref.watch(RepositoriesProviders.all);

    return Drawer(
      width: 512.0,
      child: repositoriesState.whenOrNull(
        data: (repositories) => _buildContent(repositories.keys.toIList()),
      ),
    );
  }
}
