import 'package:git/git.dart';
import 'package:gitle/git/clients/git_extensions.dart';
import 'package:gitle/git/models/repository_model.dart';
import 'package:gitle/git/providers/repositories_providers.dart';
import 'package:mek/mek.dart';

abstract class GitProviders {
  static Future<void> checkout(MutationRef ref,
      ({RepositoryModel repository, String commitOrBranch, String? newBranchName}) args) async {
    try {
      await args.repository.gitDir.checkout(args.commitOrBranch, newBranchName: args.newBranchName);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<void> reset(MutationRef ref, ({RepositoryModel repository, int count}) args) async {
    try {
      await args.repository.gitDir.reset(count: args.count);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<String?> rebase(MutationRef ref, ({GitDir gitDir, String branchName}) args) async {
    try {
      return await args.gitDir.rebase(args.branchName);
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

  static Future<void> commitPush(
    MutationRef ref,
    GitDir gitDir, {
    bool amend = false,
    required String message,
    List<String> filePaths = const [],
    bool push = false,
    PushForce? pushForce,
    bool setUpstream = false,
  }) async {
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

  static Future<void> pull(MutationRef ref, ({GitDir gitDir, String remoteBranchName}) args) async {
    try {
      await args.gitDir.pull(args.remoteBranchName);
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
      await gitDir.push(
        setUpstream: upstream != null,
        referenceName: upstream,
        force: force,
      );
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
  }) async {
    try {
      await gitDir.createAnnotatedTag(
        name,
        commit: commitSha,
        message: message,
      );
      await gitDir.push(toOrigin: true, referenceName: name);
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
