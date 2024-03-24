// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: cast_nullable_to_non_nullable, avoid_annotating_with_dynamic

part of 'repository_model.dart';

// **************************************************************************
// DataClassGenerator
// **************************************************************************

mixin _$RepositoryModel {
  RepositoryModel get _self => this as RepositoryModel;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepositoryModel &&
          runtimeType == other.runtimeType &&
          const _GitDirEquality().equals(_self.gitDir, other.gitDir) &&
          const _CommitReferenceEquality().equals(_self.currentBranch, other.currentBranch) &&
          _self.commits == other.commits &&
          const _ListCommitReferenceEquality().equals(_self.references, other.references) &&
          _self.upstreams == other.upstreams &&
          _self.workingTree == other.workingTree &&
          _self.stashes == other.stashes &&
          _self.marks == other.marks &&
          _self.settings == other.settings;
  @override
  int get hashCode {
    var hashCode = 0;
    hashCode = $hashCombine(hashCode, const _GitDirEquality().hash(_self.gitDir));
    hashCode = $hashCombine(hashCode, const _CommitReferenceEquality().hash(_self.currentBranch));
    hashCode = $hashCombine(hashCode, _self.commits.hashCode);
    hashCode = $hashCombine(hashCode, const _ListCommitReferenceEquality().hash(_self.references));
    hashCode = $hashCombine(hashCode, _self.upstreams.hashCode);
    hashCode = $hashCombine(hashCode, _self.workingTree.hashCode);
    hashCode = $hashCombine(hashCode, _self.stashes.hashCode);
    hashCode = $hashCombine(hashCode, _self.marks.hashCode);
    hashCode = $hashCombine(hashCode, _self.settings.hashCode);
    return $hashFinish(hashCode);
  }

  @override
  String toString() => (ClassToString('RepositoryModel')
        ..add('gitDir', _self.gitDir)
        ..add('currentBranch', _self.currentBranch)
        ..add('commits', _self.commits)
        ..add('references', _self.references)
        ..add('upstreams', _self.upstreams)
        ..add('workingTree', _self.workingTree)
        ..add('stashes', _self.stashes)
        ..add('marks', _self.marks)
        ..add('settings', _self.settings))
      .toString();
}
