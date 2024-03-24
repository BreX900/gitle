import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/git/providers/git_providers.dart';
import 'package:mek/mek.dart';

class BranchDeleteDialog extends ConsumerStatefulWidget {
  final GitDir gitDir;
  final String branchName;

  const BranchDeleteDialog({
    super.key,
    required this.gitDir,
    required this.branchName,
  });

  @override
  ConsumerState<BranchDeleteDialog> createState() => _BranchDeleteDialogState();
}

class _BranchDeleteDialogState extends ConsumerState<BranchDeleteDialog> {
  late final _deleteBranch = ref.mutation(GitProviders.deleteBranch, onSuccess: (_, __) {
    context.nav.pop();
  });

  final _forceFb = FieldBloc(initialValue: false);
  final _remotesFb = FieldBloc(initialValue: false);

  late final _form = ListFieldBloc(fieldBlocs: [_remotesFb, _forceFb]);

  @override
  void dispose() {
    unawaited(_form.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIdle = ref.watchIdle(mutations: [_deleteBranch]);
    final canSubmit = ref.watchCanSubmit(_form);

    return AlertDialog(
      title: Text(
        'Are you sure you want to delete the this branch?\n${widget.branchName}',
        textAlign: TextAlign.center,
      ),
      contentPadding: const EdgeInsets.only(top: 20.0),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 384.0, minHeight: 192.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FieldSwitchListTile(
              fieldBloc: _forceFb,
              title: const Text('Force Delete'),
            ),
            FieldSwitchListTile(
              fieldBloc: _remotesFb,
              title: const Text('Delete this branch on the remote'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isIdle ? () => Navigator.of(context).pop() : null,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isIdle && canSubmit
              ? () => _deleteBranch((
                    gitDir: widget.gitDir,
                    branchName: widget.branchName,
                    force: _forceFb.state.value,
                    remote: _remotesFb.state.value,
                  ))
              : null,
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
