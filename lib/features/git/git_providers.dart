import 'package:git/git.dart';
import 'package:gitle/features/code_magic/code_magic_api.dart';
import 'package:gitle/features/code_magic/code_magic_entities.dart';
import 'package:gitle/features/code_magic/code_magic_providers.dart';
import 'package:gitle/features/git/git_extensions.dart';
import 'package:gitle/features/repositories/repositories_providers.dart';
import 'package:gitle/features/repositories/repository_model.dart';
import 'package:mek/mek.dart';
import 'package:mekart/mekart.dart';

abstract class GitProviders {
  static Future<void> checkout(
    MutationRef ref, {
    required RepositoryModel repository,
    required String commitOrBranch,
    required String? newBranchName,
  }) async {
    try {
      await repository.gitDir.checkout(commitOrBranch, newBranchName: newBranchName);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<void> reset(
    MutationRef ref, {
    required RepositoryModel repository,
    required int count,
  }) async {
    try {
      await repository.gitDir.reset(count: count);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<String?> rebase(
    MutationRef ref, {
    required GitDir gitDir,
    required String branchName,
  }) async {
    try {
      return await gitDir.rebase(branchName);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<String?> cherryPick(MutationRef ref, GitDir gitDir, String commitSha) async {
    try {
      return await gitDir.cherryPick(commitSha, noCommit: true);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<String> rebaseContinue(MutationRef ref, GitDir gitDir) async {
    try {
      return await gitDir.rebaseContinue(editor: true);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<String> rebaseAbort(MutationRef ref, GitDir gitDir) async {
    try {
      return await gitDir.rebaseAbort();
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<void> createBranch(
    MutationRef ref, {
    required GitDir gitDir,
    required String startPoint,
    required String branchName,
    required bool checkout,
  }) async {
    try {
      if (checkout) {
        await gitDir.checkout(startPoint, newBranchName: branchName);
      } else {
        await gitDir.branch(branchName, startPoint: startPoint);
      }
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<void> renameBranch(
    MutationRef ref, {
    required GitDir gitDir,
    required String currentName,
    required String newName,
  }) async {
    try {
      await gitDir.branchRename(currentName, newName);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<void> deleteBranch(
    MutationRef ref, {
    required GitDir gitDir,
    required String branchName,
    required bool remote,
    required bool force,
  }) async {
    try {
      if (remote) await gitDir.pushDelete(branchName);
      await gitDir.branchDelete(branchName, force: force);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<void> commit(
    MutationRef ref,
    GitDir gitDir, {
    bool amend = false,
    required String message,
    List<String> filePaths = const [],
  }) async {
    try {
      await _commit(gitDir, amend: amend, message: message, filePaths: filePaths);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static (String, String?, String)? splitCommitMessage(String line) {
    final regExp = RegExp(r'^(\w+)(\(\w+\))?: (.+)');
    final match = regExp.firstMatch(line);
    if (match == null) return null;

    return (match.group(1)!, match.group(2), match.group(3)!);
  }

  static Future<void> commitPush(
    MutationRef ref,
    GitDir gitDir, {
    bool amend = false,
    String? scope,
    required String message,
    List<String> filePaths = const [],
    bool push = false,
    PushForce? pushForce,
    bool setUpstream = false,
  }) async {
    if (scope != null) {
      message = message
          .split('\n')
          .map((text) {
            final groups = splitCommitMessage(text);
            if (groups == null) return text;

            return '${groups.$1}${groups.$2 ?? '($scope)'}: ${groups.$3}';
          })
          .join('\n');
    }

    try {
      await _commit(gitDir, amend: amend, message: message, filePaths: filePaths);
      if (push) {
        final branch = await gitDir.currentBranch();
        await gitDir.push(
          setUpstream: setUpstream,
          referenceName: setUpstream ? branch.name : null,
          force: pushForce,
        );
      }
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<void> fetch(
    MutationRef ref,
    GitDir gitDir, {
    String? remoteBranchName,
    String? localBranch,
    bool prune = false,
  }) async {
    try {
      await gitDir.fetch(
        remoteBranchName: remoteBranchName,
        localBranch: localBranch,
        prune: prune,
      );
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<void> pull(
    MutationRef ref, {
    required GitDir gitDir,
    required String remoteBranchName,
  }) async {
    try {
      await gitDir.pull(remoteBranchName);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<void> push(
    MutationRef ref, {
    required GitDir gitDir,
    required String? upstream,
    required PushForce? force,
  }) async {
    try {
      await gitDir.push(setUpstream: upstream != null, referenceName: upstream, force: force);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<void> createTag(
    MutationRef ref, {
    required GitDir gitDir,
    required String? commitSha,
    required String name,
    required String? message,
    required CodeMagicJobEntity? codeMagicJob,
  }) async {
    try {
      await gitDir.createAnnotatedTag(name, commit: commitSha, message: message?.nullIfEmpty);
      await gitDir.push(toOrigin: true, referenceName: name);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
    if (codeMagicJob != null) {
      for (final workflowId in codeMagicJob.workflowIds) {
        await CodeMagicApi.instance.startBuild(
          appId: codeMagicJob.appId,
          workflowId: workflowId,
          tag: name,
          branch: null,
        );
        print('Started build for appId: ${codeMagicJob.appId}, workflowId: $workflowId');
      }
      ref.invalidate(CodeMagicProviders.builds);
    }
  }

  static Future<void> deleteTag(
    MutationRef ref, {
    required GitDir gitDir,
    required String name,
    bool remote = false,
  }) async {
    try {
      await gitDir.deleteTag(name);
      if (remote) await gitDir.pushDelete(name);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<void> _commit(
    GitDir gitDir, {
    required bool amend,
    required String message,
    required List<String> filePaths,
  }) async {
    await gitDir.add();
    await gitDir.commit(amend: amend, message: message, filePaths: filePaths);
  }
}
