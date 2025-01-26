import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitle/git/clients/git_extensions.dart';
import 'package:gitle/git/models/repository_model.dart';
import 'package:mek/mek.dart';
import 'package:reactive_forms/reactive_forms.dart';

class RemoteUrlDialog extends ConsumerStatefulWidget with TypedWidgetMixin<void> {
  final RepositoryModel repository;

  const RemoteUrlDialog({
    super.key,
    required this.repository,
  });

  @override
  ConsumerState<RemoteUrlDialog> createState() => _RemoteUrlDialogState();
}

class _RemoteUrlDialogState extends ConsumerState<RemoteUrlDialog> with SourceConsumerState {
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
    final remoteUrl =
        await widget.repository.gitDir.runCommand(['ls-remote', '--get-url', 'origin']);
    _urlFieldBloc.updateValue(remoteUrl.stdout as String);
  }

  late final _updateRemoteOriginUrl = ref.mutation((ref, Nil _) async {
    await widget.repository.gitDir.runEffect(['remote', 'set-url', 'origin', _urlFieldBloc.value]);
  }, onSuccess: (_, __) {
    context.nav.pop();
  });

  @override
  Widget build(BuildContext context) {
    final isDataIdle = !ref.watchIsMutating([_updateRemoteOriginUrl]);
    final isFormDirty = ref.watch(_urlFieldBloc.provider.dirty);

    final updateRemoteOriginUrl = _urlFieldBloc.handleSubmit(_updateRemoteOriginUrl.run);

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
          onPressed: isDataIdle && isFormDirty ? () => updateRemoteOriginUrl(nil) : null,
          child: const Text('Change'),
        ),
      ],
    );
  }
}
