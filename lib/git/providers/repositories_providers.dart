import 'dart:isolate';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:git/git.dart';
import 'package:gitle/git/clients/git_extensions.dart';
import 'package:gitle/git/dto/git_dto.dart';
import 'package:gitle/git/dto/repository_dto.dart';
import 'package:gitle/git/models/repository_model.dart';
import 'package:mek/mek.dart';

abstract class RepositoriesProviders {
  static final _bin = Bin<IMap<String, RepositorySettingsDto>>(
    name: 'repositories',
    deserializer: RepositorySettingsDto.fromBin,
    serializer: RepositorySettingsDto.toBin,
    fallbackData: RepositorySettingsDto.initialBin,
  );
  static final _currentBin = Bin<String>(
    name: 'repository',
    deserializer: (data) => data as String,
  );

  static final all = StreamProvider((ref) {
    return _bin.stream.map((e) {
      return e ?? RepositorySettingsDto.initialBin;
    });
  });

  static final currentGitDir = StreamProvider((ref) {
    return _currentBin.stream.asyncSwitchMap((path) async {
      if (path == null) return null;
      return await GitDir.fromExisting(path);
    });
  });

  static final pathsFb = Provider.autoDispose.family((ref, String _) {
    return FieldBloc<IList<String>>(initialValue: const IListConst([]));
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

    final referencesNames =
        ref.watch(ref.watch(pathsFb(gitDir.path)).select((state) => state.value));

    return await Isolate.run(() async {
      return await _read(gitDir, referencesNames: referencesNames, settings: settings);
    });
  });

  static Future<void> add(Ref ref, void _) async {
    final dirPath = await FilePicker.platform.getDirectoryPath();
    if (dirPath == null) return;

    final paths = await _bin.read();
    if (paths.containsKey(dirPath)) throw StateError('Already has $dirPath');

    await _bin.set(dirPath, const RepositorySettingsDto());
    await _currentBin.write(dirPath);
  }

  static Future<void> select(String repositoryPath) async {
    await _currentBin.write(repositoryPath);
  }

  static Future<void> remove(Ref ref, String dirPath) async {
    final currentDirPath = await _currentBin.readOrNull();
    if (currentDirPath == dirPath) await _currentBin.delete();
    await _bin.remove(dirPath);
  }

  static Future<void> toggleBranchesProtection(Ref ref, {required bool isEnabled}) async {
    final gitDir = await ref.read(currentGitDir.future);
    final repository = await ref.read(current.future);
    final settings = repository!.settings.change((c) => c
      ..protectedBranches =
          isEnabled ? const IListConst(['master', 'develop', 'main']) : const IListConst([]));

    await _bin.set(gitDir!.path, settings);
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
      commits: data.$3.asIList(),
      references: data.$2.asIList(),
      upstreams: data.$6.asIList(),
      workingTree: data.$4.asIList(),
      stashes: data.$5.asIList(),
      marks: Mark.from(references: data.$2, branches: data.$6).asIList(),
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
