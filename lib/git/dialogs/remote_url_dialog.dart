import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/git/clients/git_extensions.dart';
import 'package:gitle/git/models/repository_model.dart';
import 'package:mek/mek.dart';
import 'package:reactive_forms/reactive_forms.dart';

class RemoteUrlDialog extends SourceConsumerStatefulWidget with TypedWidgetMixin<void> {
  final RepositoryModel repository;

  const RemoteUrlDialog({super.key, required this.repository});

  @override
  SourceConsumerState<RemoteUrlDialog> createState() => _RemoteUrlDialogState();
}

class _RemoteUrlDialogState extends SourceConsumerState<RemoteUrlDialog> {
  final _urlFieldBloc = FormControlTyped(initialValue: '');

  @override
  void initState() {
    super.initState();
    unawaited(_initForm());
  }

  @override
  void dispose() {
    _urlFieldBloc.dispose();
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

  late final _updateRemoteOriginUrlMutation = scope.mutationV2((ref, None _) async {
    await widget.repository.gitDir.runEffect(['remote', 'set-url', 'origin', _urlFieldBloc.value]);
  });

  void _updateRemoteOriginUrl() {
    _urlFieldBloc.markAsDisabled();
    _updateRemoteOriginUrlMutation(
      none,
      onError: (error) {
        _urlFieldBloc.markAsEnabled();
        AppUtils.showErrorSnackBar(context, error);
      },
      onSuccess: (_) => context.nav.pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDataIdle = !scope.watchIsMutating([_updateRemoteOriginUrlMutation]);
    final isFormDirty = scope.watch(_urlFieldBloc.source.dirty);

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
