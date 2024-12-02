import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/common/branch_utils.dart';
import 'package:gitle/git/dto/git_dto.dart';
import 'package:gitle/git/providers/git_providers.dart';
import 'package:gitle/git/widgets/sha_text.dart';
import 'package:mek/mek.dart';
import 'package:reactive_forms/reactive_forms.dart';

class BranchCreateDialog extends ConsumerStatefulWidget with TypedWidgetMixin<void> {
  final GitDir gitDir;
  final Sha startPoint;

  const BranchCreateDialog({
    super.key,
    required this.gitDir,
    required this.startPoint,
  });

  @override
  ConsumerState<BranchCreateDialog> createState() => _BranchCreateDialogState();
}

class _BranchCreateDialogState extends ConsumerState<BranchCreateDialog> {
  final _typeFb = FormControlTypedOptional<BranchType>();
  final _nameFb = FormControlTyped<String>(
    initialValue: '',
    validators: [ValidatorsTyped.required()],
  );
  final _checkoutFb = FormControlTyped(
    initialValue: false,
  );

  late final _form = FormArray<void>([_typeFb, _nameFb, _checkoutFb]);

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  late final _createBranch = ref.mutation((ref, Nil _) {
    return GitProviders.createBranch(
      ref,
      gitDir: widget.gitDir,
      branchName: _resolveBranchName(),
      startPoint: widget.startPoint,
      checkout: _checkoutFb.value,
    );
  }, onSuccess: (_, __) {
    context.nav.pop();
  });

  String _resolveBranchName() => _typeFb.value.toName(_nameFb.value);

  @override
  Widget build(BuildContext context) {
    final isIdle = !ref.watchIsMutating([_createBranch]);
    final createBranch = _form.handleSubmit(_createBranch, keepDisabled: true);

    return AlertDialog(
      title: Row(
        children: [
          const Text('Create branch at commit '),
          ShaText(widget.startPoint, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Text(':'),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 384.0, minHeight: 192.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReactiveSegmentedButton<BranchType>(
              formControl: _typeFb,
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              segments: BranchType.values.map((type) {
                return ButtonSegment(
                  value: type,
                  label: Text(type.name),
                );
              }).toList(),
            ),
            ReactiveTextField(
              formControl: _nameFb,
              minLines: 1,
              maxLines: 10,
              inputFormatters: [BranchUtils.textFormatter],
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            ReactiveSwitchListTile(
              formControl: _checkoutFb,
              title: const Text('Checkout'),
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isIdle ? () => Navigator.of(context).pop() : null,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isIdle ? () => createBranch(nil) : null,
          child: const Text('Create'),
        ),
      ],
    );
  }
}
