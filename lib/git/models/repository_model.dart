import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:git/git.dart';
import 'package:gitle/git/dto/git_dto.dart';
import 'package:gitle/git/dto/repository_dto.dart';
import 'package:mek_data_class/mek_data_class.dart';

part 'repository_model.g.dart';

@DataClass()
class RepositoryModel with _$RepositoryModel {
  @DataField(equality: _GitDirEquality())
  final GitDir gitDir;
  @DataField(equality: _CommitReferenceEquality())
  final BranchReference currentBranch;

  final IList<LogDto> commits;
  @DataField(equality: _ListCommitReferenceEquality())
  final IList<CommitReference> references;
  final IList<BranchReferenceWithUpstream> upstreams;

  final bool isRebaseInProgress;
  final IList<FileDto> workingTree;

  final IList<Stash> stashes;

  final IList<Mark> marks;

  final RepositorySettingsDto settings;

  const RepositoryModel({
    required this.gitDir,
    required this.currentBranch,
    required this.commits,
    required this.references,
    required this.upstreams,
    required this.isRebaseInProgress,
    required this.workingTree,
    required this.stashes,
    required this.marks,
    required this.settings,
  });

  bool get isWorkingTreeClean => workingTree.isEmpty;

  // bool get currentBranchHasRemote =>
  //     commits.any((e) => e.isRemote && e.name == .startsWith('refs/remotes/${currentBranch.name}'));
}

class _GitDirEquality implements Equality<GitDir> {
  const _GitDirEquality();

  @override
  bool equals(GitDir e1, GitDir e2) => e1.path == e2.path;

  @override
  int hash(GitDir e) => Object.hash(e.path, e.path);

  @override
  bool isValidKey(Object? o) => throw UnimplementedError();
}

class _ListCommitReferenceEquality extends IterableEquality<CommitReference> {
  const _ListCommitReferenceEquality() : super(const _CommitReferenceEquality());
}

class _CommitReferenceEquality implements Equality<CommitReference> {
  const _CommitReferenceEquality();

  @override
  bool equals(CommitReference e1, CommitReference e2) =>
      e1.reference == e2.reference && e1.sha == e2.sha;

  @override
  int hash(CommitReference e) => Object.hash(e.reference, e.sha);

  @override
  bool isValidKey(Object? o) => throw UnimplementedError();
}
