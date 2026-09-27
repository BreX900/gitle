import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/features/git/git_extensions.dart';
import 'package:gitle/features/git/git_providers.dart';
import 'package:gitle/features/repositories/repositories_providers.dart';
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

  const FormCommitAtom({super.key, required this.gitDir, this.filePaths});

  @override
  ConsumerState<FormCommitAtom> createState() => _FormCommitAtomState();
}

class _FormCommitAtomState extends ConsumerState<FormCommitAtom> {
  late final _mutation = MutationController(ref);

  final _messageControl = FormControlTyped(initialValue: '');
  final _amendControl = FormControlTyped(initialValue: false);
  final _pushTypeControl = FormControlTypedOptional<_PushType>();
  final _pushForceTypeControl = FormControlTypedOptional<PushForce>();
  final _scopeControl = FormControlTypedOptional<String>();

  late final _form = FormArray<void>([
    _messageControl,
    _amendControl,
    _pushTypeControl,
    _pushForceTypeControl,
    // Do not add _scopeControl to not reset on submit
  ]);

  @override
  void initState() {
    super.initState();
    _amendControl.valueChanges.listen(_amendListener);
    _pushTypeControl.valueChanges.listen((value) {
      if (value == null) _pushForceTypeControl.reset();
    });
  }

  @override
  void dispose() {
    _scopeControl.dispose();
    _form.dispose();
    _mutation.dispose();
    super.dispose();
  }

  void _commitPush() {
    _mutation(
      (ref) async {
        final branch = await widget.gitDir.currentBranch();
        final repository = await ref.read(RepositoriesProviders.current.future);
        if (repository!.config.protectedBranches.contains(branch.branchName)) {
          throw StateError('Cant push to ${branch.branchName}!');
        }

        await GitProviders.commitPush(
          ref,
          widget.gitDir,
          amend: _amendControl.value,
          scope: _scopeControl.value,
          message: _messageControl.value,
          filePaths: widget.filePaths?.call() ?? [],
          push: _pushTypeControl.value != null,
          setUpstream: _pushTypeControl.value == _PushType.setUpstream,
          pushForce: _pushForceTypeControl.value,
        );
      },
      onError: (error, stackTrace) => AppUtils.showErrorSnackBar(context, error),
      onSuccess: (_) => _form.reset(),
    );
  }

  Future<void> _amendListener(bool amend) async {
    if (!amend) return;
    final data = (await ref.read(RepositoriesProviders.current.future))!;
    final log = data.commits.firstWhere((e) => e.commit == data.currentBranch.sha);

    if (_messageControl.value.isNotEmpty) {
      final canReplace = await _showReplaceMessageDialog();
      if (!canReplace) return;
    }
    _messageControl.updateValue(log.message.join('\n'));
  }

  Future<bool> _showReplaceMessageDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace current text with previous commit message?'),
        actions: [
          TextButton(onPressed: () => context.nav.pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => context.nav.pop(true), child: const Text('Replace')),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final hasPush = !ref.watch(_pushTypeControl.provider.value.isNull);
    final isAmend = ref.watch(_amendControl.provider.value) ?? false;

    final error = ref.watch(_mutation.provider.select((state) => state.errorOrNull));

    final repository = ref.watch(RepositoriesProviders.current).requireValue!;

    final isIdle = !ref.watch(_mutation.provider.isPending);

    final content = Column(
      children: [
        if (repository.config.commitScopes.isNotEmpty)
          Padding(
            padding: const .symmetric(horizontal: 16.0),
            child: ReactiveDropdownField<String>(
              formControl: _scopeControl,
              decoration: const InputDecoration(
                labelText: 'Scope',
                suffixIcon: ReactiveClearButton(),
              ),
              items: repository.config.commitScopes.map((scope) {
                return DropdownMenuItem(value: scope, child: Text(scope));
              }).toList(),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ReactiveTextField(
            formControl: _messageControl,
            minLines: 1,
            maxLines: 10,
            decoration: InputDecoration(
              labelText: 'Message',
              errorText: error != null ? '$error' : null,
              suffixIcon: const ReactiveClearButton(),
            ),
          ),
        ),
        ReactiveSwitchListTile(formControl: _amendControl, title: const Text('Amend last commit')),
        const Divider(),
        ReactiveFormField<_PushType, _PushType>(
          formControl: _pushTypeControl,
          builder: (field) => RadioGroup<_PushType>(
            groupValue: field.value,
            onChanged: field.didChange,
            child: Grid(
              crossAxisCount: 2,
              children: _PushType.values.map((value) {
                return RadioListTile(
                  enabled: field.control.enabled,
                  toggleable: true,
                  value: value,
                  title: Text(value.translate()),
                );
              }).toList(),
            ),
          ),
        ),
        if (hasPush)
          ReactiveFormField<PushForce, PushForce>(
            formControl: _pushForceTypeControl,
            builder: (field) => RadioGroup<PushForce>(
              groupValue: field.value,
              onChanged: field.didChange,
              child: Grid(
                crossAxisCount: 2,
                children: PushForce.values.map((value) {
                  return RadioListTile(
                    toggleable: true,
                    value: value,
                    enabled: field.control.enabled,
                    title: Text(value.translate()),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
    return HarmonicSingleChildScrollView(
      child: Column(
        mainAxisAlignment: .spaceBetween,
        children: [
          content,
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(
                  onPressed: isIdle && (!repository.isWorkingTreeClean || isAmend)
                      ? _commitPush
                      : null,
                  child: hasPush ? const Text('Commit/Push') : const Text('Commit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
