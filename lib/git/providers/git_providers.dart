import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/git/clients/git_extensions.dart';
import 'package:gitle/git/models/repository_model.dart';
import 'package:gitle/git/providers/repositories_providers.dart';

abstract class GitProviders {
  static Future<void> checkout(Ref ref,
      ({RepositoryModel repository, String commitOrBranch, String? newBranchName}) args) async {
    try {
      await args.repository.gitDir.checkout(args.commitOrBranch, newBranchName: args.newBranchName);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<void> reset(Ref ref, ({RepositoryModel repository, int count}) args) async {
    try {
      await args.repository.gitDir.reset(count: args.count);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<String?> rebase(Ref ref, ({GitDir gitDir, String branchName}) args) async {
    try {
      return await args.gitDir.rebase(args.branchName);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<String> rebaseContinue(Ref ref, GitDir gitDir) async {
    try {
      return await gitDir.rebaseContinue(editor: true);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<String> rebaseAbort(Ref ref, GitDir gitDir) async {
    try {
      return await gitDir.rebaseContinue(editor: true);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<void> createBranch(
      Ref ref,
      ({
        GitDir gitDir,
        String startPoint,
        String branchName,
        bool checkout,
      }) args) async {
    try {
      if (args.checkout) {
        await args.gitDir.checkout(args.startPoint, newBranchName: args.branchName);
      } else {
        await args.gitDir.branch(args.branchName, startPoint: args.startPoint);
      }
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<void> renameBranch(
      Ref ref, ({GitDir gitDir, String currentName, String newName}) args) async {
    try {
      await args.gitDir.branchRename(args.currentName, args.newName);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<void> deleteBranch(
      Ref ref,
      ({
        GitDir gitDir,
        String branchName,
        bool remote,
        bool force,
      }) args) async {
    try {
      if (args.remote) await args.gitDir.pushDelete(args.branchName);
      await args.gitDir.branchDelete(args.branchName, force: args.force);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<void> commit(
    Ref ref,
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
    Ref ref,
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

  static Future<void> fetch(Ref ref,
      ({GitDir gitDir, String? remoteBranchName, String? localBranch, bool prune}) args) async {
    try {
      await args.gitDir.fetch(
          remoteBranchName: args.remoteBranchName,
          localBranch: args.localBranch,
          prune: args.prune);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<void> pull(Ref ref, ({GitDir gitDir, String remoteBranchName}) args) async {
    try {
      await args.gitDir.pull(args.remoteBranchName);
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<void> push(
      Ref ref,
      ({
        GitDir gitDir,
        String? upstream,
        PushForce? force,
      }) args) async {
    try {
      await args.gitDir.push(
        setUpstream: args.upstream != null,
        referenceName: args.upstream,
        force: args.force,
      );
    } finally {
      ref.invalidate(RepositoriesProviders.current);
    }
  }

  static Future<void> createTag(
      Ref ref, ({GitDir gitDir, String? commitSha, String name, String? message}) args) async {
    try {
      await args.gitDir.createAnnotatedTag(
        args.name,
        commit: args.commitSha,
        message: args.message,
      );
      await args.gitDir.push(toOrigin: true, referenceName: args.name);
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
