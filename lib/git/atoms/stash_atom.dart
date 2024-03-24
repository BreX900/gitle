import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitle/git/clients/git_extensions.dart';
import 'package:gitle/git/models/repository_model.dart';
import 'package:gitle/git/providers/repositories_providers.dart';

class StashAtom extends ConsumerStatefulWidget {
  final RepositoryModel repository;

  const StashAtom({
    super.key,
    required this.repository,
  });

  @override
  ConsumerState<StashAtom> createState() => _StashAtomState();
}

class _StashAtomState extends ConsumerState<StashAtom> {
  @override
  Widget build(BuildContext context) {
    final stashes = widget.repository.stashes;

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () async {
                await widget.repository.gitDir.stashPush();
                ref.invalidate(RepositoriesProviders.current);
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        Expanded(
          child: ListView.builder(
            itemCount: stashes.length,
            itemBuilder: (context, index) {
              final stash = stashes[index];

              return ListTile(
                title: Text('${stash.author.username} ${stash.author.date}'),
                subtitle: Text(stash.message.join(' ')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // IconButton(
                    //   onPressed: () {},
                    //   tooltip: 'git stash ...???',
                    //   icon: const Icon(Icons.edit_outlined),
                    // ),
                    IconButton(
                      onPressed: () async {
                        await widget.repository.gitDir.stashApply(stash.name);
                        ref.invalidate(RepositoriesProviders.current);
                      },
                      tooltip: 'git stash apply',
                      icon: const Icon(Icons.unarchive_outlined),
                    ),
                    IconButton(
                      onPressed: () async {
                        await widget.repository.gitDir.stashDrop(stash.name);
                        ref.invalidate(RepositoriesProviders.current);
                      },
                      tooltip: 'git stash delete',
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
