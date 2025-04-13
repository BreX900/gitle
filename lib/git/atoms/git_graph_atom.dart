import 'dart:async';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/common/gitle_icons.dart';
import 'package:gitle/git/clients/git_extensions.dart';
import 'package:gitle/git/dialogs/branch_create_dialog.dart';
import 'package:gitle/git/dialogs/branch_delete_dialog.dart';
import 'package:gitle/git/dialogs/branch_pull_dialog.dart';
import 'package:gitle/git/dialogs/branch_rename_dialog.dart';
import 'package:gitle/git/dialogs/push_dialog.dart';
import 'package:gitle/git/dialogs/tag_create_dialog.dart';
import 'package:gitle/git/dialogs/tag_delete_dialog.dart' show TagDeleteDialog;
import 'package:gitle/git/dto/git_dto.dart';
import 'package:gitle/git/models/repository_model.dart';
import 'package:gitle/git/providers/git_providers.dart';
import 'package:gitle/git/widgets/graph_widgets.dart';
import 'package:gitle/git/widgets/sha_text.dart';
import 'package:intl/intl.dart';
import 'package:mek/mek.dart';

class GitGraphAtom extends ConsumerStatefulWidget {
  final RepositoryModel repository;

  const GitGraphAtom({
    super.key,
    required this.repository,
  });

  @override
  ConsumerState<GitGraphAtom> createState() => _GitGraphAtomState();
}

class _GitGraphAtomState extends ConsumerState<GitGraphAtom> {
  late final _checkout = ref.mutation(GitProviders.checkout, onError: (_, error) {
    AppUtils.showErrorSnackBar(context, error);
  });
  late final _rebase = ref.mutation(GitProviders.rebase, onError: (_, error) {
    AppUtils.showErrorSnackBar(context, error);
  }, onSuccess: (_, message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message ?? 'Rebase completed!'),
    ));
  });
  late final _cherryPick = ref.mutation((ref, String commitSha) async {
    return await GitProviders.cherryPick(ref, widget.repository.gitDir, commitSha);
  }, onError: (_, error) {
    AppUtils.showErrorSnackBar(context, error);
  }, onSuccess: (_, message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message ?? 'Rebase completed!'),
    ));
  });
  late final _fetch = ref.mutation((ref, (String, String) __) async {
    final (remote, local) = __;
    await GitProviders.fetch(
      ref,
      widget.repository.gitDir,
      remoteBranchName: remote,
      localBranch: local,
    );
  }, onError: (_, error) {
    AppUtils.showErrorSnackBar(context, error);
  });
  late final _reset = ref.mutation(GitProviders.reset, onError: (_, error) {
    AppUtils.showErrorSnackBar(context, error);
  });

  Future<void> _showTagCreateDialog(GitDir gitDir, Sha commit) async {
    await showTypedDialog(
      context: context,
      builder: (context) => TagCreateDialog(
        gitDir: gitDir,
        startPoint: commit,
      ),
    );
  }

  Future<void> _showBranchPushDialog(GitDir gitDir, {required String branchName}) async {
    await showTypedDialog(
      context: context,
      builder: (context) => PushDialog(
        gitDir: gitDir,
        branchName: branchName,
      ),
    );
  }

  Future<void> _showBranchPullDialog(
    GitDir gitDir, {
    required String localBranchName,
    required String remoteBranchName,
  }) async {
    await showTypedDialog(
      context: context,
      builder: (context) => BranchPullDialog(
        gitDir: gitDir,
        localBranch: localBranchName,
        remoteBranchName: remoteBranchName,
      ),
    );
  }

  Future<void> _showBranchCreateDialog(GitDir gitDir, Sha commit) async {
    await showTypedDialog(
      context: context,
      builder: (context) => BranchCreateDialog(
        gitDir: gitDir,
        startPoint: commit,
      ),
    );
  }

  Future<void> _showBranchRenameDialog(GitDir gitDir, String branchName) async {
    await showTypedDialog(
      context: context,
      builder: (context) => BranchRenameDialog(gitDir: gitDir, branchName: branchName),
    );
  }

  Future<void> _showBranchDeleteDialog(GitDir gitDir, String branchName) async {
    await showTypedDialog(
      context: context,
      builder: (context) => BranchDeleteDialog(gitDir: gitDir, branchName: branchName),
    );
  }

  Future<void> _showTagDeleteDialog(GitDir gitDir, String branchName) async {
    await showTypedDialog(
      context: context,
      builder: (context) => TagDeleteDialog(gitDir: gitDir, name: branchName),
    );
  }

  int _calculateResetDeep(IList<LogDto> logs, String currentRef, LogDto target) {
    var deep = 0;
    LogDto? cursor;
    for (final log in logs) {
      if (cursor == null) {
        if (log.commit == currentRef) {
          cursor = log;
        } else {
          continue;
        }
      }

      if (cursor.parent != log.commit) continue;

      deep += 1;
      cursor = log;

      if (cursor.commit == target.commit) return deep;

      if (deep > 10) return -1;
    }
    return -1;
  }

  Future<void> _showCommitMenu(BuildContext context, Offset offset, LogDto log) async {
    final isCurrentBranch = widget.repository.currentBranch.sha == log.commit;
    final deep =
        _calculateResetDeep(widget.repository.commits, widget.repository.currentBranch.sha, log);
    await showMenu<void>(
      context: context,
      position: MekUtils.getMenuPosition(context, offset),
      constraints: const BoxConstraints(minHeight: 32.0, minWidth: 128.0),
      items: [
        PopupMenuItemTile(
          onTap: () => _showTagCreateDialog(widget.repository.gitDir, log.commit),
          leading: const Icon(GitleIcons.tag),
          title: const Text('Create Tag...'),
        ),
        PopupMenuItemTile(
          onTap: () => _showBranchCreateDialog(widget.repository.gitDir, log.commit),
          leading: const Icon(GitleIcons.flow_branch),
          title: const Text('Create Branch...'),
        ),
        const PopupMenuDivider(),
        if (!isCurrentBranch)
          PopupMenuItemTile(
            onTap: () => _cherryPick(log.commit),
            leading: const Icon(Icons.unarchive),
            title: const Text('Cherry pick current commit on Branch'),
            subtitle: Text('git cherry-pick ${ShaText.resolve(log.commit)} --no-commit'),
          ),
        PopupMenuItemTile(
          enabled: deep > 0,
          onTap: () => _reset((repository: widget.repository, count: deep)),
          leading: const Icon(Icons.delete_outline),
          title: const Text('Reset'),
          subtitle: Text('reset HEAD~$deep --soft'),
        ),
        const PopupMenuDivider(),
        PopupMenuItemTile(
          onTap: () => AppUtils.setClipboard(log.commit),
          leading: const Icon(Icons.data_object),
          title: const Text('Copy commit hash to clipboard'),
        ),
        PopupMenuItemTile(
          onTap: () => AppUtils.setClipboard(log.message.join('\n')),
          leading: const Icon(Icons.message_outlined),
          title: const Text('Copy commit message to clipboard'),
        ),
      ],
    );
  }

  Future<void> _showTagMenu(BuildContext context, Offset offset, CommitReference commit) async {
    await showMenu<void>(
      context: context,
      position: MekUtils.getMenuPosition(context, offset),
      constraints: const BoxConstraints(minHeight: 32.0, minWidth: 128.0),
      items: [
        PopupMenuItemTile(
          onTap: () => _showTagDeleteDialog(widget.repository.gitDir, commit.name),
          leading: const Icon(Icons.delete),
          title: const Text('Delete Tag...'),
          subtitle: Text('tag --delete ${commit.name}'),
        ),
        // if (commit.isLocal)
        PopupMenuItemTile(
          onTap: () => _showBranchPushDialog(widget.repository.gitDir, branchName: commit.name),
          leading: const Icon(Icons.upload_outlined),
          title: const Text('Push tag...'),
          subtitle: Text('push ${commit.name}'),
        ),
        const PopupMenuDivider(),
        PopupMenuItemTile(
          onTap: () => AppUtils.setClipboard(commit.name),
          leading: const Icon(Icons.abc),
          title: const Text('Copy tag name to clipboard'),
        ),
      ],
    );
  }

  Future<void> _showBranchMenu(
    BuildContext context,
    Offset offset,
    bool hasHead,
    CommitReference commit,
    CommitReference? upstream,
  ) async {
    final head = widget.repository.currentBranch;

    await showMenu<void>(
      context: context,
      position: MekUtils.getMenuPosition(context, offset),
      constraints: const BoxConstraints(minHeight: 32.0, minWidth: 128.0),
      items: [
        if (!hasHead)
          PopupMenuItemTile(
            onTap: () => _checkout((
              repository: widget.repository,
              commitOrBranch: commit.name,
              newBranchName: commit.isRemote ? commit.toBranchName() : null,
            )),
            leading: const Icon(Icons.read_more),
            title: const Text('Checkout Branch'),
            subtitle: Text(
                'checkout ${commit.name}${commit.isRemote ? ' -b ${commit.toBranchName()}' : ''}'),
          ),
        if (commit.isLocal)
          PopupMenuItemTile(
            onTap: () => _showBranchRenameDialog(widget.repository.gitDir, commit.name),
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Rename Branch...'),
            subtitle: Text('branch --move ${commit.name} <NEW_NAME>'),
          ),
        if (commit.isLocal && !hasHead)
          PopupMenuItemTile(
            onTap: () => _showBranchDeleteDialog(widget.repository.gitDir, commit.name),
            leading: const Icon(Icons.delete),
            title: const Text('Delete Branch...'),
            subtitle: Text('branch --delete ${commit.name}'),
          ),
        if (!hasHead)
          PopupMenuItemTile(
            onTap: () => _rebase((gitDir: widget.repository.gitDir, branchName: commit.name)),
            leading: const Icon(Icons.compare_arrows),
            title: const Text('Rebase current branch on Branch'),
            subtitle: Text('rebase ${commit.name}'),
          ),
        if (commit.isLocal)
          PopupMenuItemTile(
            onTap: () => _showBranchPushDialog(widget.repository.gitDir, branchName: commit.name),
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Push branch...'),
            subtitle: Text('push ${commit.name}'),
          ),
        if (commit.isRemote)
          PopupMenuItemTile(
            onTap: () => _showBranchPullDialog(
              widget.repository.gitDir,
              localBranchName: head.name,
              remoteBranchName: commit.toBranchName(),
            ),
            leading: const Icon(Icons.download_outlined),
            title: const Text('Pull into current branch...'),
            subtitle: Text('pull origin ${commit.toBranchName()}'),
          ),
        if (upstream != null && !hasHead) ...[
          const PopupMenuDivider(),
          PopupMenuItemTile(
            onTap: () => _fetch((upstream.toBranchName(), commit.name)),
            leading: const Icon(Icons.download_outlined),
            title: const Text('Fetch'),
            subtitle: Text('fetch origin ${upstream.toBranchName()}:${commit.name}'),
          ),
        ],
        const PopupMenuDivider(),
        PopupMenuItemTile(
          onTap: () => AppUtils.setClipboard(commit.name),
          leading: const Icon(Icons.abc),
          title: const Text('Copy branch name to clipboard'),
        ),
        PopupMenuItemTile(
          onTap: () =>
              AppUtils.setClipboard(commit.name.replaceFirst('/', ': ').replaceAll('_', ' ')),
          leading: const Icon(Icons.abc),
          title: const Text('Copy branch name as commit message to clipboard'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.Hm('it').add_yMd();

    final isIdle = !ref.watchIsMutating([_checkout, _rebase, _rebase, _cherryPick, _fetch]);

    final head = widget.repository.currentBranch;
    final marks = widget.repository.marks;

    final child = GitGraph<LogDto>(
      nodes: widget.repository.commits.map((e) {
        return GitNode(
          id: e.commit,
          parent: e.parent,
          data: e,
        );
      }).toList(),
      builder: (context, log) {
        final commitMarks = marks.where((e) => e.sha == log.commit);

        return GraphTile(
          onSecondaryTapDown: isIdle
              ? (details) => unawaited(_showCommitMenu(context, details.localPosition, log))
              : null,
          leading: commitMarks.map((mark) {
            final local = mark.local;
            final remote = mark.remote;
            final isTag = remote?.isTag ?? false;

            return Builder(builder: (context) {
              return GraphChip(
                isSelected: head.reference == mark.local?.reference,
                icon: isTag ? const Icon(GitleIcons.tag) : const Icon(GitleIcons.flow_branch),
                children: [
                  if (local != null)
                    _MarkView(
                      onDoubleTap: isIdle && !mark.hasHead
                          ? () => _checkout((
                                repository: widget.repository,
                                commitOrBranch: local.name,
                                newBranchName: null,
                              ))
                          : null,
                      onSecondaryTapUp: isIdle
                          ? (details) => unawaited(_showBranchMenu(
                              context, details.localPosition, mark.hasHead, local, remote))
                          : null,
                      text: local.name,
                    ),
                  if (remote != null)
                    _MarkView(
                      onDoubleTap: isIdle && !mark.hasHead
                          ? () => _checkout((
                                repository: widget.repository,
                                commitOrBranch: remote.name,
                                newBranchName: remote.toBranchName(),
                              ))
                          : null,
                      onSecondaryTapUp: isIdle
                          ? (details) => remote.isTag
                              ? unawaited(_showTagMenu(context, details.localPosition, remote))
                              : unawaited(_showBranchMenu(
                                  context, details.localPosition, mark.hasHead, remote, null))
                          : null,
                      text: local != null ? 'origin' : remote.name,
                    ),
                ],
              );
            });
          }).toList(),
          content: Tooltip(
            waitDuration: const Duration(seconds: 5),
            message: log.message.join('\n'),
            child: Text(log.message.join(' ↲ ')),
          ),
          trailing: [
            Text(dateFormat.format(log.author.date)),
            Text(log.author.username),
            ShaText(log.commit),
          ],
        );
      },
    );
    return SelectionArea(child: child);
  }
}

class _MarkView extends StatelessWidget {
  final VoidCallback? onDoubleTap;
  final GestureTapUpCallback? onSecondaryTapUp;
  final String text;

  const _MarkView({
    required this.onDoubleTap,
    required this.onSecondaryTapUp,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final scope = ChipGraphScope.of(context);

    return InkWell(
      borderRadius:
          scope.isLast ? const BorderRadius.horizontal(right: Radius.circular(8.0)) : null,
      onDoubleTap: onDoubleTap,
      onSecondaryTapUp: onSecondaryTapUp,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Text(text),
        ),
      ),
    );
  }
}
