import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/features/code_magic/code_magic_dto.dart';
import 'package:gitle/features/code_magic/code_magic_entities.dart';
import 'package:gitle/features/code_magic/code_magic_providers.dart';
import 'package:gitle/features/git/branch_utils.dart';
import 'package:gitle/features/git/git_providers.dart';
import 'package:gitle/features/repositories/repository_entity.dart';
import 'package:gitle/shared/build_async_value_extensions.dart';
import 'package:gitle/shared/sha_text.dart';
import 'package:mek/mek.dart';
import 'package:reactive_forms/reactive_forms.dart';

class TagCreateDialog extends ConsumerStatefulWidget with TypedWidgetMixin<void> {
  final RepositoryConfigEntity config;
  final GitDir gitDir;
  final String startPoint;

  const TagCreateDialog({
    super.key,
    required this.config,
    required this.gitDir,
    required this.startPoint,
  });

  @override
  ConsumerState<TagCreateDialog> createState() => _TagCreateDialogState();
}

class _TagCreateDialogState extends ConsumerState<TagCreateDialog> {
  late final _mutation = MutationController(ref);

  final _nameFb = FormControlTyped<String>(
    initialValue: '',
    validators: [ValidatorsTyped.required()],
  );
  final _messageFb = FormControlTyped(initialValue: '');
  final _pushableToRemoteFb = FormControlTyped(disabled: true, initialValue: true);
  final _codeMagicJobControl = FormControlTypedOptional<CodeMagicJobEntity>();

  late final _form = FormArray([_nameFb, _messageFb, _pushableToRemoteFb]);

  @override
  void initState() {
    super.initState();
    if (widget.config.codeMagic.jobs.isNotEmpty) _form.add(_codeMagicJobControl);
  }

  @override
  void dispose() {
    _form.dispose();
    _mutation.dispose();
    super.dispose();
  }

  void _createTag() {
    _form.markAsDisabled();

    _mutation(
      (ref) async => await GitProviders.createTag(
        ref,
        gitDir: widget.gitDir,
        commitSha: widget.startPoint,
        name: _nameFb.value,
        message: _messageFb.value,
        codeMagicJob: _codeMagicJobControl.value,
      ),
      onError: (error, stackTrace) {
        _form.markAsEnabled();
        AppUtils.showErrorSnackBar(context, error);
      },
      onSuccess: (_) => Navigator.pop(context),
    );
  }

  Widget _buildContent({required IList<Application> applications}) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 384.0, minHeight: 192.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8.0,
        children: [
          ReactiveTextField(
            formControl: _nameFb,
            inputFormatters: [BranchUtils.textFormatter],
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          ReactiveTextField(
            formControl: _messageFb,
            minLines: 1,
            maxLines: 10,
            decoration: const InputDecoration(labelText: 'Message'),
          ),
          ReactiveSwitchListTile(
            formControl: _pushableToRemoteFb,
            contentPadding: .zero,
            title: const Text('Push to remote'),
          ),
          ReactiveDropdownField<CodeMagicJobEntity>(
            formControl: _codeMagicJobControl,
            decoration: const InputDecoration(labelText: 'CodeMagic Job'),
            items: [
              const DropdownMenuItem(child: Text('None')),
              ...widget.config.codeMagic.jobs.map((value) {
                final application = applications.firstWhere((e) => e.id == value.appId);
                return DropdownMenuItem(
                  value: value,
                  child: Text('${application.name} > ${value.workflowIds.join(',')}'),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIdle = !ref.watch(_mutation.provider.isPending);
    final createTag = _form.handleSubmit(_createTag);

    final state = ref.watch(CodeMagicProviders.apps);

    return AlertDialog(
      title: Row(
        children: [
          const Text('Add Tag to commit '),
          ShaText(widget.startPoint, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: state.buildView(data: (apps) => _buildContent(applications: apps)),
      actions: [
        TextButton(
          onPressed: isIdle ? () => Navigator.of(context).pop() : null,
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: isIdle ? createTag : null, child: const Text('Create')),
      ],
    );
  }
}
