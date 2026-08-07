import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitle/features/code_magic/code_magic_dto.dart';
import 'package:gitle/features/code_magic/code_magic_entities.dart';
import 'package:gitle/features/code_magic/code_magic_providers.dart';
import 'package:gitle/shared/build_async_value_extensions.dart';
import 'package:reactive_forms/reactive_forms.dart';

class CodeMagicWorkflowDialog extends ConsumerStatefulWidget {
  const CodeMagicWorkflowDialog({super.key});

  @override
  ConsumerState<CodeMagicWorkflowDialog> createState() => _CodeMagicWorkflowDialogState();
}

class _CodeMagicWorkflowDialogState extends ConsumerState<CodeMagicWorkflowDialog> {
  final _appIdControl = FormControl<String>();
  final _workflowIdsControl = FormControl<String>();
  late final _form = FormArray([_appIdControl, _workflowIdsControl]);

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  void _submit() {
    final result = CodeMagicJobEntity(
      appId: _appIdControl.value!,
      workflowIds: _workflowIdsControl.value!.split(',').lockUnsafe,
    );
    Navigator.pop(context, result);
  }

  Widget _buildContent({required IList<Application> apps}) {
    return Column(
      mainAxisSize: .min,
      children: [
        ReactiveDropdownField<String>(
          formControl: _appIdControl,
          items: apps.map((value) {
            return DropdownMenuItem(value: value.id, child: Text(value.name));
          }).toList(),
          decoration: const InputDecoration(labelText: 'App'),
        ),
        ReactiveTextField<String>(
          formControl: _workflowIdsControl,
          decoration: const InputDecoration(
            labelText: 'Workflow ids',
            helperText: 'Separate by comma',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appsState = ref.watch(CodeMagicProviders.apps);

    return AlertDialog(
      title: const Text('Create new job'),
      content: IntrinsicHeight(
        child: appsState.buildView(data: (apps) => _buildContent(apps: apps)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
