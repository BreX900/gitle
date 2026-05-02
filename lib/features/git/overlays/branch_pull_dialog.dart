import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/features/git/git_providers.dart';
import 'package:mek/mek.dart';

class BranchPullDialog extends ConsumerStatefulWidget with TypedWidgetMixin<void> {
  final GitDir gitDir;
  final String localBranch;
  final String remoteBranchName;

  const BranchPullDialog({
    super.key,
    required this.gitDir,
    required this.localBranch,
    required this.remoteBranchName,
  });

  @override
  ConsumerState<BranchPullDialog> createState() => _BranchPullDialogState();
}

class _BranchPullDialogState extends ConsumerState<BranchPullDialog> {
  late final _mutation = MutationController(ref);

  @override
  void dispose() {
    _mutation.dispose();
    super.dispose();
  }

  void _pullBranch() {
    _mutation(
      (ref) async => await GitProviders.pull(
        ref,
        gitDir: widget.gitDir,
        remoteBranchName: widget.remoteBranchName,
      ),
      onError: (error, stackTrace) => AppUtils.showErrorSnackBar(context, error),
      onSuccess: (_) => Navigator.pop(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIdle = !ref.watch(_mutation.provider.isPending);

    return AlertDialog(
      title: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Are you sure you want to pull the remote branch '),
            TextSpan(
              text: widget.remoteBranchName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: ' into '),
            TextSpan(
              text: widget.localBranch,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: ' (the current branch)?'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isIdle ? () => Navigator.of(context).pop() : null,
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: isIdle ? _pullBranch : null, child: const Text('Pull')),
      ],
    );
  }
}
