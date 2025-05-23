import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/git/clients/git_extensions.dart';
import 'package:gitle/git/providers/git_providers.dart';
import 'package:gitle/git/providers/repositories_providers.dart';
import 'package:mek/mek.dart';
import 'package:reactive_forms/reactive_forms.dart';

enum _PushType {
  enabled,
  setUpstream;

  String translate() {
    return switch (this) {
      _PushType.enabled => 'Push',
      _PushType.setUpstream => 'Push with upstream',
    };
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
  final _messageFb = FormControlTyped(initialValue: '');
  final _amendFb = FormControlTyped(initialValue: false);
  final _pushFb = FormControlTypedOptional<_PushType>();
  final _pushForceTypeFb = FormControlTypedOptional<PushForce>();

  late final _form = FormArray<void>([_messageFb, _amendFb, _pushFb, _pushForceTypeFb]);

  @override
  void initState() {
    super.initState();
    _amendFb.valueChanges.listen(_amendListener);
  }

  @override
  void dispose() {
    _form.dispose();
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
      amend: _amendFb.value,
      message: _messageFb.value,
      filePaths: widget.filePaths?.call() ?? [],
      push: _pushFb.value != null,
      setUpstream: _pushFb.value == _PushType.setUpstream,
      pushForce: _pushForceTypeFb.value,
    );
  }, onError: (_, error) {
    AppUtils.showErrorSnackBar(context, error);
  }, onSuccess: (_, __) {
    _form.reset();
  });

  Future<void> _amendListener(bool amend) async {
    if (!amend) return;
    final data = (await ref.read(RepositoriesProviders.current.future))!;
    final log = data.commits.firstWhere((e) => e.commit == data.currentBranch.sha);

    if (_messageFb.value.isNotEmpty) {
      final canReplace = await _showReplaceMessageDialog();
      if (!canReplace) return;
    }
    _messageFb.updateValue(log.message.join('\n'));
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
    final hasPush = ref.watch(_pushFb.provider.hasValue);
    final isAmend = ref.watch(_amendFb.provider.value) ?? false;

    final error = ref.watch(_commitPush.select((state) => state.errorOrNull));

    final repository = ref.watch(RepositoriesProviders.current).requireValue!;

    final isIdle = !ref.watchIsMutating([_commitPush]);

    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ReactiveTextField(
            formControl: _messageFb,
            minLines: 1,
            maxLines: 10,
            decoration: InputDecoration(
              labelText: 'Message',
              errorText: error != null ? '$error' : null,
              suffixIcon: const ReactiveClearButton(),
            ),
          ),
        ),
        ReactiveSwitchListTile(
          formControl: _amendFb,
          title: const Text('Amend last commit'),
        ),
        const Divider(),
        ReactiveFormField<_PushType, _PushType>(
          formControl: _pushFb,
          builder: (field) => Grid(
            crossAxisCount: 2,
            children: _PushType.values.map((value) {
              final isEnabled = field.control.enabled;

              return RadioListTile(
                groupValue: field.value,
                toggleable: true,
                value: value,
                onChanged: isEnabled ? field.didChange : null,
                title: Text(value.translate()),
              );
            }).toList(),
          ),
        ),
        if (hasPush)
          ReactiveFormField<PushForce, PushForce>(
            formControl: _pushForceTypeFb,
            builder: (field) => Grid(
              crossAxisCount: 2,
              children: PushForce.values.map((value) {
                final isEnabled = field.control.enabled;

                return RadioListTile(
                  groupValue: field.value,
                  toggleable: true,
                  value: value,
                  onChanged: isEnabled ? field.didChange : null,
                  title: Text(value.translate()),
                );
              }).toList(),
            ),
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
