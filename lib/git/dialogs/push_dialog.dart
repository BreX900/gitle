import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/git/clients/git_extensions.dart';
import 'package:gitle/git/providers/git_providers.dart';
import 'package:mek/mek.dart';

enum _PushType {
  setUpstream,
  forceWithLease,
  force;

  String translate() {
    switch (this) {
      case _PushType.setUpstream:
        return 'Push with upstream';
      case _PushType.forceWithLease:
        return 'Force Push With Lease';
      case _PushType.force:
        return 'Force Push';
    }
  }

  PushForce? toForce() {
    switch (this) {
      case _PushType.setUpstream:
        return null;
      case _PushType.forceWithLease:
        return PushForce.enabledWithLease;
      case _PushType.force:
        return PushForce.enabled;
    }
  }
}

class PushDialog extends ConsumerStatefulWidget {
  final GitDir gitDir;
  final String branchName;

  const PushDialog({
    super.key,
    required this.gitDir,
    required this.branchName,
  });

  @override
  ConsumerState<PushDialog> createState() => _PushDialogState();
}

class _PushDialogState extends ConsumerState<PushDialog> {
  late final _push = ref.mutation(GitProviders.push, onSuccess: (_, __) {
    context.nav.pop();
  });

  final _pushForceFb = FieldBloc<_PushType?>(initialValue: null);

  late final _form = ListFieldBloc(fieldBlocs: [_pushForceFb]);

  @override
  void dispose() {
    unawaited(_form.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIdle = ref.watchIdle(mutations: [_push]);
    final canSubmit = ref.watchCanSubmit2(_form, shouldDirty: false);

    return AlertDialog(
      title: Text('Push ${widget.branchName}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 384.0, minHeight: 192.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FieldGroupBuilder(
              fieldBloc: _pushForceFb,
              valuesCount: _PushType.values.length,
              valueBuilder: (state, index) {
                final value = _PushType.values[index];
                final isEnabled = state.isEnabled;

                return RadioListTile(
                  groupValue: state.value,
                  toggleable: true,
                  value: value,
                  onChanged: isEnabled ? _pushForceFb.changeValue : null,
                  title: Text(value.translate()),
                );
              },
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
              ? () => _push((
                    gitDir: widget.gitDir,
                    force: _pushForceFb.state.value?.toForce(),
                    upstream: _pushForceFb.state.value == _PushType.setUpstream
                        ? widget.branchName
                        : null,
                  ))
              : null,
          child: const Text('Push'),
        ),
      ],
    );
  }
}
