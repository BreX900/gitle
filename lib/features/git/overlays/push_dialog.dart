import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/features/git/git_extensions.dart';
import 'package:gitle/features/git/git_providers.dart';
import 'package:mek/mek.dart';
import 'package:reactive_forms/reactive_forms.dart';

class PushDialog extends ConsumerStatefulWidget with TypedWidgetMixin<void> {
  final GitDir gitDir;
  final String branchName;

  const PushDialog({super.key, required this.gitDir, required this.branchName});

  @override
  ConsumerState<PushDialog> createState() => _PushDialogState();
}

class _PushDialogState extends ConsumerState<PushDialog> {
  late final _mutation = MutationController(ref);
  final _pushWithUpstreamFb = FormControlTyped<bool>(initialValue: false);
  final _pushForceFb = FormControlTypedOptional<PushForce>();

  late final _form = FormArray<void>([_pushWithUpstreamFb, _pushForceFb]);

  @override
  void dispose() {
    _form.dispose();
    _mutation.dispose();
    super.dispose();
  }

  void _push() {
    _form.markAsDisabled();
    _mutation(
      (ref) async => await GitProviders.push(
        ref,
        gitDir: widget.gitDir,
        force: _pushForceFb.value,
        upstream: _pushWithUpstreamFb.value ? widget.branchName : null,
      ),
      onError: (error, stackTrace) {
        _form.markAsEnabled();
        AppUtils.showErrorSnackBar(context, error);
      },
      onSuccess: (_) => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIdle = !ref.watch(_mutation.provider.isPending);
    final push = _form.handleSubmit(_push);

    return AlertDialog(
      title: Text('Push ${widget.branchName}'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 384.0, minHeight: 192.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReactiveSwitchListTile(
              formControl: _pushWithUpstreamFb,
              title: const Text('Push with upstream'),
            ),
            ReactiveFormField<PushForce, PushForce>(
              formControl: _pushForceFb,
              builder: (field) => RadioGroup<PushForce>(
                groupValue: field.value,
                onChanged: field.didChange,
                child: Column(
                  children: PushForce.values.map((value) {
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isIdle ? () => Navigator.of(context).pop() : null,
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: isIdle ? push : null, child: const Text('Push')),
      ],
    );
  }
}
