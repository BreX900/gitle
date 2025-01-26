import 'dart:isolate';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/git/clients/git_extensions.dart';
import 'package:gitle/git/clients/instances.dart';
import 'package:gitle/git/dto/git_dto.dart';
import 'package:gitle/git/dto/repository_dto.dart';
import 'package:gitle/git/models/repository_model.dart';
import 'package:mek/mek.dart';
import 'package:mekart/mekart.dart';
import 'package:rxdart/rxdart.dart';

class InvalidGitDirFailure implements Exception {
  final String path;

  const InvalidGitDirFailure({required this.path});
}

extension on BinSession {
  BinStore<IMap<String, RepositorySettingsDto>> get repositories => BinStore(
        session: this,
        name: Instances.resolveBinName('repositories'),
        deserializer: RepositorySettingsDto.fromBin,
        serializer: RepositorySettingsDto.toBin,
        fallbackData: RepositorySettingsDto.initialBin,
      );
  BinStore<String?> get currentRepository => BinStore(
        session: this,
        name: Instances.resolveBinName('repository'),
        deserializer: (data) => data as String,
        fallbackData: null,
      );
}

abstract class RepositoriesProviders {
  static final all = StreamProvider((ref) => Instances.bin.repositories.stream);

  static final currentGitDir = StreamProvider((ref) {
    return Instances.bin.currentRepository.stream.switchMap((path) async* {
      if (path == null) {
        yield null;
        return;
      }
      if (!await GitDir.isGitDir(path)) throw InvalidGitDirFailure(path: path);
      yield await GitDir.fromExisting(path);
    });
  });

  static final referencesNames = StateProvider.autoDispose.family((ref, String _) {
    return const ISet<String>.empty();
  });

  static final current = FutureProvider.autoDispose((ref) async {
    final gitDir = await ref.watch(currentGitDir.future);
    if (gitDir == null) return null;

    final settings = await ref
        .watch(all.selectAsync((value) => value[gitDir.path] ?? const RepositorySettingsDto()));

    // ref.onDispose(Directory(path)
    //     .watch(recursive: true)
    //     .debounceTime(const Duration(seconds: 3))
    //     .listen((event) => ref.invalidateSelf())
    //     .cancel);

    final referencesNames = ref.watch(RepositoriesProviders.referencesNames(gitDir.path));

    return await Isolate.run(() async {
      return await _read(gitDir, referencesNames: referencesNames, settings: settings);
    });
  });

  static Future<void> add(MutationRef ref, void _) async {
    final dirPath = await FilePicker.platform.getDirectoryPath();
    if (dirPath == null) return;

    await Instances.bin.runTransaction((tx) async {
      final paths = await tx.repositories.read();
      if (paths.containsKey(dirPath)) throw StateError('Already has $dirPath');

      await tx.repositories.set(dirPath, const RepositorySettingsDto());
      await tx.currentRepository.write(dirPath);
    });
  }

  static Future<void> select(String repositoryPath) async {
    await Instances.bin.currentRepository.write(repositoryPath);
  }

  static Future<void> remove(MutationRef ref, String dirPath) async {
    await Instances.bin.runTransaction((tx) async {
      final currentDirPath = await tx.currentRepository.read();
      if (currentDirPath == dirPath) await tx.currentRepository.write('');
      await tx.repositories.remove(dirPath);
    });
  }

  static Future<void> toggleBranchesProtection(MutationRef ref, {required bool isEnabled}) async {
    final gitDir = await ref.read(currentGitDir.future);
    final repository = await ref.read(current.future);
    final settings = repository!.settings.change((c) => c
      ..protectedBranches =
          isEnabled ? const IListConst(['master', 'develop', 'main']) : const IListConst([]));

    await Instances.bin.repositories.set(gitDir!.path, settings);
  }

  static Future<RepositoryModel> _read(
    GitDir gitDir, {
    required Iterable<String> referencesNames,
    required RepositorySettingsDto settings,
  }) async {
    final data = await (
      gitDir.currentBranch(),
      gitDir.showRef(), // head: true
      gitDir.logs(tags: true, paths: referencesNames, maxCount: 200),
      gitDir.status(),
      //gitDir.lsRemotes(heads: true).benchmark('lsRemotes'), // , tags: true
      gitDir.stashList(),
      gitDir.branchUpstreams(),
    ).wait;

    return RepositoryModel(
      gitDir: gitDir,
      currentBranch: data.$1,
      commits: data.$3.asImmutable(),
      references: data.$2.asImmutable(),
      upstreams: data.$6.asImmutable(),
      workingTree: data.$4.asImmutable(),
      stashes: data.$5.asImmutable(),
      marks: Mark.from(references: data.$2, branches: data.$6).asImmutable(),
      settings: settings,
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
