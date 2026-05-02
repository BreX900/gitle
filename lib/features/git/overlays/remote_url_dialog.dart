import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/features/git/git_extensions.dart';
import 'package:gitle/features/repositories/repository_model.dart';
import 'package:mek/mek.dart';
import 'package:reactive_forms/reactive_forms.dart';

class RemoteUrlDialog extends ConsumerStatefulWidget with TypedWidgetMixin<void> {
  final RepositoryModel repository;

  const RemoteUrlDialog({super.key, required this.repository});

  @override
  ConsumerState<RemoteUrlDialog> createState() => _RemoteUrlDialogState();
}

class _RemoteUrlDialogState extends ConsumerState<RemoteUrlDialog> {
  late final _mutation = MutationController(ref);

  final _urlFieldBloc = FormControlTyped(initialValue: '');

  @override
  void initState() {
    super.initState();
    unawaited(_initForm());
  }

  @override
  void dispose() {
    _urlFieldBloc.dispose();
    _mutation.dispose();
    super.dispose();
  }

  Future<void> _initForm() async {
    final remoteUrl = await widget.repository.gitDir.runCommand([
      'ls-remote',
      '--get-url',
      'origin',
    ]);
    _urlFieldBloc.updateValue(remoteUrl.stdout as String);
  }

  void _updateRemoteOriginUrl() {
    _urlFieldBloc.markAsDisabled();
    _mutation(
      (ref) async => await widget.repository.gitDir.runEffect([
        'remote',
        'set-url',
        'origin',
        _urlFieldBloc.value,
      ]),
      onError: (error, stackTrace) {
        _urlFieldBloc.markAsEnabled();
        AppUtils.showErrorSnackBar(context, error);
      },
      onSuccess: (_) => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDataIdle = !ref.watch(_mutation.provider.isPending);
    final isFormDirty = ref.watch(_urlFieldBloc.provider.dirty);

    final updateRemoteOriginUrl = _urlFieldBloc.handleSubmit(_updateRemoteOriginUrl);

    return AlertDialog(
      title: const Text('Remote origin url'),
      content: ReactiveTextField(
        formControl: _urlFieldBloc,
        decoration: const InputDecoration(labelText: 'Url'),
      ),
      actions: [
        TextButton(
          onPressed: isDataIdle ? () => Navigator.of(context).pop() : null,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isDataIdle && isFormDirty ? updateRemoteOriginUrl : null,
          child: const Text('Change'),
        ),
      ],
    );
  }
}
