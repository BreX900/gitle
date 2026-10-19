import 'dart:async';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/features/git/screens/git_logs_screen.dart';
import 'package:gitle/features/repositories/repositories_providers.dart';
import 'package:gitle/shared/build_async_value_extensions.dart';
import 'package:mek/mek.dart';
import 'package:path/path.dart' as p;

class RepositoriesDrawerView extends ConsumerStatefulWidget {
  const RepositoriesDrawerView({super.key});

  @override
  ConsumerState<RepositoriesDrawerView> createState() => _RepositoriesDrawerViewState();
}

class _RepositoriesDrawerViewState extends ConsumerState<RepositoriesDrawerView> {
  late final _mutation = MutationController(ref);

  @override
  void dispose() {
    _mutation.dispose();
    super.dispose();
  }

  void _addRepository() {
    _mutation(
      (ref) async => await RepositoriesProviders.add(ref, null),
      onError: (error, stackTrace) => AppUtils.showErrorSnackBar(context, error),
    );
  }

  void _removeRepository(String repositoryPath) {
    _mutation(
      (ref) async => await RepositoriesProviders.remove(ref, repositoryPath),
      onError: (error, stackTrace) => AppUtils.showErrorSnackBar(context, error),
    );
  }

  Future<void> _selectRepository(String repositoryPath) async {
    Scaffold.of(context).closeDrawer();
    await RepositoriesProviders.select(repositoryPath);
  }

  Widget _buildRepositories(IList<String> repositories) {
    final isIdle = !ref.watch(_mutation.provider.isPending);
    final repository = ref.watch(
      RepositoriesProviders.current.select((state) {
        return state.value?.gitDir.path;
      }),
    );

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return ListView.builder(
      key: const PageStorageKey<String>('repositories'),
      primary: false,
      padding: const .only(top: 8.0),
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
                child: const ListTile(title: Text('Delete'), trailing: Icon(Icons.delete_outline)),
              ),
            ],
          ),
        );

        if (prevRepositoryPath != null &&
            p.dirname(prevRepositoryPath) == p.dirname(repositoryPath)) {
          return child;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (prevRepositoryPath != null) const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text(
                AppUtils.removeHomePath(p.dirname(repositoryPath)),
                style: textTheme.titleMedium,
              ),
            ),
            child,
          ],
        );
      },
    );
  }

  Widget _buildContent(IList<String> repositories) {
    final isIdle = !ref.watch(_mutation.provider.isPending);

    return Column(
      children: [
        Expanded(child: _buildRepositories(repositories)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Logs',
              onPressed: () {
                Scaffold.of(context).closeDrawer();
                context.nav.push(const GitLogsScreen());
              },
              icon: const Icon(Icons.bug_report_outlined),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: FloatingActionButton(
                onPressed: isIdle ? _addRepository : null,
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final repositoriesState = ref.watch(RepositoriesProviders.all);

    return repositoriesState.buildView(
      data: (repositories) => _buildContent(repositories.keys.toIList()),
    );
  }
}
