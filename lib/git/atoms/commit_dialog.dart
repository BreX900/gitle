import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/git/clients/git_extensions.dart';
import 'package:gitle/git/providers/git_providers.dart';
import 'package:gitle/git/providers/repositories_providers.dart';
import 'package:mek/mek.dart';

enum _PushType {
  enabled,
  setUpstream,
  forceWithLease,
  force;

  String translate() {
    switch (this) {
      case _PushType.enabled:
        return 'Push';
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
      case _PushType.enabled:
      case _PushType.setUpstream:
        return null;
      case _PushType.forceWithLease:
        return PushForce.enabledWithLease;
      case _PushType.force:
        return PushForce.enabled;
    }
  }
}

class FormCommitAtom extends ConsumerStatefulWidget {
  final GitDir gitDir;
  final ValueGetter<List<String>>? filePaths;

  const FormCommitAtom({
    super.key,
    required this.gitDir,
    this.filePaths,
  });

  @override
  ConsumerState<FormCommitAtom> createState() => _FormCommitAtomState();
}

class _FormCommitAtomState extends ConsumerState<FormCommitAtom> {
  final _messageFb = FieldBloc(initialValue: '');
  final _amendFb = FieldBloc(initialValue: false);
  final _typeFb = FieldBloc<_PushType?>(initialValue: null);

  late final _form = ListFieldBloc(fieldBlocs: [_messageFb, _amendFb, _typeFb]);

  @override
  void initState() {
    super.initState();
    _amendFb.stream.map((state) => state.value).listen(_amendListener);
  }

  @override
  void dispose() {
    unawaited(_form.close());
    super.dispose();
  }

  late final _commitPush = ref.mutation((ref, arg) async {
    final branch = await widget.gitDir.currentBranch();
    final repository = await ref.read(RepositoriesProviders.current.future);
    if (repository!.settings.protectedBranches.contains(branch.branchName)) {
      throw StateError('Cant push to ${branch.branchName}!');
    }

    await GitProviders.commitPush(
      ref,
      widget.gitDir,
      amend: _amendFb.state.value,
      message: _messageFb.state.value,
      filePaths: widget.filePaths?.call() ?? [],
      push: _typeFb.state.value != null,
      setUpstream: _typeFb.state.value == _PushType.setUpstream,
      pushForce: _typeFb.state.value?.toForce(),
    );
  }, onSuccess: (_, __) {
    _form.clear();
  });

  Future<void> _amendListener(bool amend) async {
    if (!amend) return;
    final data = (await ref.read(RepositoriesProviders.current.future))!;
    final log = data.commits.firstWhere((e) => e.commit == data.currentBranch.sha);

    if (_messageFb.state.value.isNotEmpty) {
      final canReplace = await _showReplaceMessageDialog();
      if (!canReplace) return;
    }
    _messageFb.changeValue(log.message.join('\n'));
  }

  Future<bool> _showReplaceMessageDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace current text with previous commit message?'),
        actions: [
          TextButton(
            onPressed: () => context.nav.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.nav.pop(true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final hasPush = ref.watch(_typeFb.select((state) => state.value != null));
    final isAmend = ref.watch(_amendFb.select((state) => state.value));

    final error = ref.watch(_commitPush.select((state) => state.errorOrNull));

    final repository = ref.watch(RepositoriesProviders.current).requireValue!;

    final isIdle = ref.watchIdle(mutations: [_commitPush]);

    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: FieldText(
            fieldBloc: _messageFb,
            converter: FieldConvert.text,
            minLines: 1,
            maxLines: 10,
            decoration: InputDecoration(
              labelText: 'Message',
              errorText: error != null ? '$error' : null,
              suffixIcon: IconButton(
                onPressed: _messageFb.clear,
                icon: const Icon(Icons.close),
              ),
            ),
          ),
        ),
        FieldSwitchListTile(
          fieldBloc: _amendFb,
          title: const Text('Amend last commit'),
        ),
        const Divider(),
        FieldGroupBuilder(
          fieldBloc: _typeFb,
          style: const GroupStyle.table(),
          valuesCount: _PushType.values.length,
          valueBuilder: (state, index) {
            final value = _PushType.values[index];
            final isEnabled = state.isEnabled;

            return RadioListTile(
              groupValue: state.value,
              toggleable: true,
              value: value,
              onChanged: isEnabled ? _typeFb.changeValue : null,
              title: Text(value.translate()),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: isIdle && (!repository.isWorkingTreeClean || isAmend)
                    ? () => _commitPush(null)
                    : null,
                child: hasPush ? const Text('Commit/Push') : const Text('Commit'),
              ),
            ],
          ),
        ),
      ],
    );
    return SingleChildScrollView(
      child: content,
    );
  }
}
