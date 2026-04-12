import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitle/common/instances.dart';
import 'package:gitle/features/code_magic/code_magic_api.dart';
import 'package:gitle/features/code_magic/code_magic_entities.dart';
import 'package:gitle/features/notifications/notifications_manager.dart';
import 'package:gitle/features/repositories/repositories_providers.dart';
import 'package:mek/mek.dart';
import 'package:mekart/mekart.dart';

abstract final class CodeMagicProviders {
  static final apps = FutureProvider((ref) async {
    return await CodeMagicApi.instance.fetchApps();
  });

  static final builds = StreamProvider((ref) {
    return NotificationsManager.instance.watchCodeMagicBuilds();
  });

  static Future<void> createJob(MutationRef ref, CodeMagicJobEntity job) {
    return Instances.bin.runTransaction((tx) async {
      final gitDir = await ref.read(RepositoriesProviders.currentGitDir.future);
      final repositories = await tx.repositories.requireRead();
      final repository = repositories[gitDir!.path]!;

      final settings = repository.copyWith(
        codeMagic: repository.codeMagic.copyWith(
          jobs: [...repository.codeMagic.jobs, job].lockUnsafe,
        ),
      );

      await tx.repositories.set(gitDir.path, settings);
    });
  }

  static Future<void> deleteJob(MutationRef ref, CodeMagicJobEntity job) {
    return Instances.bin.runTransaction((tx) async {
      final gitDir = await ref.read(RepositoriesProviders.currentGitDir.future);
      final repositories = await tx.repositories.requireRead();
      final repository = repositories[gitDir!.path]!;

      final settings = repository.copyWith(
        codeMagic: repository.codeMagic.copyWith(
          jobs: repository.codeMagic.jobs.where((e) => e != job).toIList(),
        ),
      );

      await Instances.bin.repositories.set(gitDir.path, settings);
    });
  }

  static Future<void> cancelBuild(MutationRef ref, String buildId) async {
    await CodeMagicApi.instance.cancelBuild(buildId);
    ref.invalidate(builds);
  }
}
