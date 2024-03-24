import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitle/git/clients/git_extensions.dart';
import 'package:gitle/git/models/repository_model.dart';
import 'package:mek/mek.dart';

class RemoteUrlDialog extends ConsumerStatefulWidget with TypedWidgetMixin<void> {
  final RepositoryModel repository;

  const RemoteUrlDialog({
    super.key,
    required this.repository,
  });

  @override
  ConsumerState<RemoteUrlDialog> createState() => _RemoteUrlDialogState();
}

class _RemoteUrlDialogState extends ConsumerState<RemoteUrlDialog> {
  final _urlFieldBloc = FieldBloc(initialValue: '');

  @override
  void initState() {
    super.initState();
    unawaited(_initForm());
  }

  @override
  void dispose() {
    unawaited(_urlFieldBloc.close());
    super.dispose();
  }

  Future<void> _initForm() async {
    final remoteUrl =
        await widget.repository.gitDir.runCommand(['ls-remote', '--get-url', 'origin']);
    _urlFieldBloc.updateInitialValue(remoteUrl.stdout as String);
  }

  late final _updateRemoteOriginUrl = ref.mutation((ref, _) async {
    await widget.repository.gitDir
        .runEffect(['remote', 'set-url', 'origin', _urlFieldBloc.state.value]);
  }, onSuccess: (_, __) {
    context.nav.pop();
  });

  @override
  Widget build(BuildContext context) {
    final isDataIdle = ref.watchIdle(mutations: [_updateRemoteOriginUrl]);
    final canSubmit = ref.watchCanSubmit(_urlFieldBloc);

    return AlertDialog(
      title: const Text('Remote origin url'),
      content: FieldText(
        fieldBloc: _urlFieldBloc,
        converter: FieldConvert.text,
        decoration: const InputDecoration(labelText: 'Url'),
      ),
      actions: [
        TextButton(
          onPressed: isDataIdle ? () => Navigator.of(context).pop() : null,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isDataIdle && canSubmit ? () => _updateRemoteOriginUrl(null) : null,
          child: const Text('Change'),
        ),
      ],
    );
  }
}
