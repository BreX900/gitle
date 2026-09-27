import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/common/instances.dart';
import 'package:gitle/features/dashboard/dashboard_providers.dart';
import 'package:gitle/features/git/git_dto.dart';
import 'package:gitle/features/git/git_extensions.dart';
import 'package:gitle/features/repositories/repository_entity.dart';
import 'package:gitle/features/repositories/repository_model.dart';
import 'package:mek/mek.dart';
import 'package:mekart/mekart.dart';
import 'package:rxdart/rxdart.dart';

class InvalidGitDirFailure implements Exception {
  final String path;

  const InvalidGitDirFailure({required this.path});
}

extension RepositoriesBin on BinSession {
  BinStore<IMap<String, RepositoryConfigEntity>> get repositories => BinStore(
    session: this,
    name: Instances.resolveBinName('repositories_v4'),
    deserializer: RepositoryConfigEntity.fromBin,
    serializer: RepositoryConfigEntity.toBin,
    fallbackData: RepositoryConfigEntity.initialBin,
  );
}

abstract class RepositoriesProviders {
  static final all = StreamProvider((ref) => Instances.bin.repositories.stream);

  static final currentGitDir = StreamProvider((ref) {
    return Instances.bin.dashboard.stream.map((data) => data.group.itemUid).distinct().switchMap((
      path,
    ) async* {
      if (path == null) {
        yield null;
        return;
      }
      if (!await GitDir.isGitDir(path)) throw InvalidGitDirFailure(path: path);
      yield await GitDir.fromExisting(path);
    });
  });

  static final referencesNames = Provider.autoDispose.family((ref, String _) {
    return const ISet<String>.empty();
  });

  static final current = FutureProvider.autoDispose((ref) async {
    final gitDir = await ref.watch(currentGitDir.future);
    if (gitDir == null) return null;

    ref.invalidateWhenAppResume();

    final settings = await ref.watch(
      all.selectAsync((value) => value[gitDir.path] ?? const RepositoryConfigEntity()),
    );

    // ref.onDispose(Directory(path)
    //     .watch(recursive: true)
    //     .debounceTime(const Duration(seconds: 3))
    //     .listen((event) => ref.invalidateSelf())
    //     .cancel);
    //
    final isRebaseInProgress = File('${gitDir.path}/.git/REBASE_HEAD').existsSync();

    final referencesNames = ref.watch(RepositoriesProviders.referencesNames(gitDir.path));

    final gitDirPath = gitDir.path;
    return await Isolate.run(() async {
      return await _read(
        gitDirPath,
        referencesNames: referencesNames,
        settings: settings,
        isRebaseInProgress: isRebaseInProgress,
      );
    });
  });

  static Future<void> add(MutationRef? ref, void _) async {
    final rawRepositoryPath = await FilePicker.getDirectoryPath();
    if (rawRepositoryPath == null) return;

    final repositoryPath = Directory(rawRepositoryPath).absolute.resolveSymbolicLinksSync();

    await Instances.bin.runTransaction((tx) async {
      final paths = await tx.repositories.read();
      if (paths.containsKey(repositoryPath)) throw StateError('Already has $repositoryPath');
      var dashboard = await tx.dashboard.read();
      final group = dashboard.group;

      dashboard = dashboard.copyWith(
        groupUid: group.uid,
        groups: dashboard.groups.replaceFirst(
          from: group,
          to: group.copyWith(itemUid: repositoryPath, items: group.items.add(repositoryPath)),
        ),
      );

      await tx.repositories.set(repositoryPath, const RepositoryConfigEntity());
      await tx.dashboard.write(dashboard);
    });
  }

  static Future<void> select(String path) async {
    await Instances.bin.runTransaction((tx) async {
      var dashboard = await tx.dashboard.requireRead();

      final group = dashboard.groups.firstWhereOrNull((group) => group.items.contains(path));
      if (group != null) {
        dashboard = dashboard.copyWith(
          groupUid: group.uid,
          groups: dashboard.groups.replaceFirst(
            from: group,
            to: group.copyWith(itemUid: path),
          ),
        );
      } else {
        dashboard = dashboard.copyWith(
          groupUid: dashboard.group.uid,
          groups: dashboard.groups.replaceFirst(
            from: dashboard.group,
            to: dashboard.group.copyWith(itemUid: path, items: dashboard.group.items.add(path)),
          ),
        );
      }

      await tx.dashboard.write(dashboard);
    });
  }

  static Future<void> remove(MutationRef ref, String dirPath) async {
    await Instances.bin.runTransaction((tx) async {
      var dashboard = await tx.dashboard.read();
      dashboard = dashboard.copyWith(
        groups: dashboard.groups.map((group) {
          return group.copyWith(
            itemUid: group.itemUid == dirPath ? null : group.itemUid,
            items: group.items.where((e) => e != dirPath).toIList(),
          );
        }).toIList(),
      );
      await tx.dashboard.write(dashboard);
      await tx.repositories.remove(dirPath);
    });
  }

  static Future<void> toggleBranchesProtection(MutationRef ref, {required bool isEnabled}) async {
    final gitDir = await ref.read(currentGitDir.future);
    final repository = await ref.read(current.future);
    final settings = repository!.config.copyWith(
      protectedBranches: isEnabled
          ? const IListConst(['master', 'develop', 'main'])
          : const IListConst([]),
    );

    await Instances.bin.repositories.set(gitDir!.path, settings);
  }

  static Future<void> updateCommitScopes(MutationRef ref, {required IList<String> scopes}) async {
    final gitDir = await ref.read(currentGitDir.future);
    final repository = await ref.read(current.future);
    final settings = repository!.config.copyWith(commitScopes: scopes);

    await Instances.bin.repositories.set(gitDir!.path, settings);
  }

  static Future<RepositoryModel> _read(
    String gitDirPath, {
    required Iterable<String> referencesNames,
    required RepositoryConfigEntity settings,
    required bool isRebaseInProgress,
  }) async {
    final gitDir = await GitDir.fromExisting(gitDirPath);
    final data = await (
      gitDir.currentBranch(),
      gitDir.showRefExtended(dereference: true),
      gitDir.logs(tags: true, paths: referencesNames, maxCount: 512),
      gitDir.status(),
      gitDir.stashList(),
      gitDir.branchUpstreams(),
    ).wait;

    return RepositoryModel(
      path: await Directory(gitDirPath).absolute.resolveSymbolicLinks(),
      gitDir: gitDir,
      currentBranch: data.$1,
      commits: data.$3.lockUnsafe,
      references: data.$2.lockUnsafe,
      upstreams: data.$6.lockUnsafe,
      isRebaseInProgress: isRebaseInProgress,
      workingTree: data.$4.lockUnsafe,
      stashes: data.$5.lockUnsafe,
      marks: Mark.from(references: data.$2, branches: data.$6).toIList(),
      config: settings,
    );
  }
}

// extension<T> on Future<T> {
//   Future<T> benchmark(String label) {
//     // if (!kProfileMode) return this;
//     final startAt = DateTime.now();
//     return then((value) {
//       // ignore: avoid_print
//       print('$label: ${DateTime.now().difference(startAt)}');
//       return value;
//     });
//   }
// }
