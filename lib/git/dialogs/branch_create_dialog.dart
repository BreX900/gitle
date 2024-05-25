import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/common/branch_utils.dart';
import 'package:gitle/git/dto/git_dto.dart';
import 'package:gitle/git/providers/git_providers.dart';
import 'package:gitle/git/widgets/sha_text.dart';
import 'package:mek/mek.dart';

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
  final _typeFb = FieldBloc<BranchType?>(initialValue: null);
  final _nameFb = FieldBloc(
    initialValue: '',
    validator: const TextValidation(minLength: 1),
  );
  final _checkoutFb = FieldBloc(initialValue: false);

  late final _form = ListFieldBloc(fieldBlocs: [_typeFb, _nameFb, _checkoutFb]);

  @override
  void dispose() {
    unawaited(_form.close());
    super.dispose();
  }

  late final _createBranch = ref.mutation((ref, Nil _) {
    return GitProviders.createBranch(
      ref,
      gitDir: widget.gitDir,
      branchName: _resolveBranchName(),
      startPoint: widget.startPoint,
      checkout: _checkoutFb.state.value,
    );
  }, onSuccess: (_, __) {
    context.nav.pop();
  });

  String _resolveBranchName() => _typeFb.state.value.toName(_nameFb.state.value);

  @override
  Widget build(BuildContext context) {
    final isIdle = ref.watchIdle(mutations: [_createBranch]);
    final createBranch = context.handleMutation(_form, _createBranch);

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
            FieldSegmentedButton<BranchType?>(
              fieldBloc: _typeFb,
              converter: _typeFb.transform(const SetFieldConverter<BranchType?>(emptyIfNull: true)),
              emptySelectionAllowed: true,
              showSelectedIcon: false,
              segments: BranchType.values.map((type) {
                return ButtonSegment(
                  value: type,
                  label: Text(type.name),
                );
              }).toList(),
            ),
            FieldText(
              fieldBloc: _nameFb,
              converter: FieldConvert.text,
              minLines: 1,
              maxLines: 10,
              inputFormatters: [BranchUtils.textFormatter],
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            FieldSwitchListTile(
              fieldBloc: _checkoutFb,
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
