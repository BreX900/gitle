import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/features/git/branch_utils.dart';
import 'package:gitle/features/git/git_dto.dart';
import 'package:gitle/features/git/git_providers.dart';
import 'package:gitle/shared/sha_text.dart';
import 'package:mek/mek.dart';
import 'package:reactive_forms/reactive_forms.dart';

class BranchCreateDialog extends ConsumerStatefulWidget with TypedWidgetMixin<void> {
  final GitDir gitDir;
  final Sha startPoint;

  const BranchCreateDialog({super.key, required this.gitDir, required this.startPoint});

  @override
  ConsumerState<BranchCreateDialog> createState() => _BranchCreateDialogState();
}

class _BranchCreateDialogState extends ConsumerState<BranchCreateDialog> {
  late final _mutation = MutationController(ref);

  final _typeFb = FormControlTypedOptional<BranchType>();
  final _nameFb = FormControlTyped<String>(
    initialValue: '',
    validators: [ValidatorsTyped.required()],
  );
  final _checkoutFb = FormControlTyped(initialValue: false);

  late final _form = FormArray<void>([_typeFb, _nameFb, _checkoutFb]);

  @override
  void dispose() {
    _mutation.dispose();
    _form.dispose();
    super.dispose();
  }

  void _createBranch() {
    _form.markAsDisabled();
    _mutation(
      (ref) async => await GitProviders.createBranch(
        ref,
        gitDir: widget.gitDir,
        branchName: _resolveBranchName(),
        startPoint: widget.startPoint,
        checkout: _checkoutFb.value,
      ),
      onError: (error, stackTrace) {
        _form.markAsEnabled();
        AppUtils.showErrorSnackBar(context, error);
      },
      onSuccess: (_) => context.nav.pop(),
    );
  }

  String _resolveBranchName() => _typeFb.value.toName(_nameFb.value);

  @override
  Widget build(BuildContext context) {
    final isIdle = !ref.watch(_mutation.provider.isPending);
    final createBranch = _form.handleSubmit(_createBranch);

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
                return ButtonSegment(value: type, label: Text(type.name));
              }).toList(),
            ),
            ReactiveTextField(
              formControl: _nameFb,
              minLines: 1,
              maxLines: 10,
              inputFormatters: [BranchUtils.textFormatter],
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            ReactiveSwitchListTile(formControl: _checkoutFb, title: const Text('Checkout')),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isIdle ? () => Navigator.of(context).pop() : null,
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: isIdle ? createBranch : null, child: const Text('Create')),
      ],
    );
  }
}
