// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: cast_nullable_to_non_nullable, avoid_annotating_with_dynamic

part of 'git_dto.dart';

// **************************************************************************
// DataClassGenerator
// **************************************************************************

mixin _$CommandLogDto {
  CommandLogDto get _self => this as CommandLogDto;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommandLogDto &&
          runtimeType == other.runtimeType &&
          _self.name == other.name &&
          $listEquality.equals(_self.args, other.args) &&
          _self.exitCode == other.exitCode &&
          _self.message == other.message;
  @override
  int get hashCode {
    var hashCode = 0;
    hashCode = $hashCombine(hashCode, _self.name.hashCode);
    hashCode = $hashCombine(hashCode, $listEquality.hash(_self.args));
    hashCode = $hashCombine(hashCode, _self.exitCode.hashCode);
    hashCode = $hashCombine(hashCode, _self.message.hashCode);
    return $hashFinish(hashCode);
  }
}

mixin _$LogActionDto {
  LogActionDto get _self => this as LogActionDto;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogActionDto &&
          runtimeType == other.runtimeType &&
          _self.username == other.username &&
          _self.email == other.email &&
          _self.date == other.date;
  @override
  int get hashCode {
    var hashCode = 0;
    hashCode = $hashCombine(hashCode, _self.username.hashCode);
    hashCode = $hashCombine(hashCode, _self.email.hashCode);
    hashCode = $hashCombine(hashCode, _self.date.hashCode);
    return $hashFinish(hashCode);
  }
}

mixin _$LogDto {
  LogDto get _self => this as LogDto;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogDto &&
          runtimeType == other.runtimeType &&
          _self.commit == other.commit &&
          _self.parent == other.parent &&
          _self.author == other.author &&
          _self.committer == other.committer &&
          $listEquality.equals(_self.message, other.message);
  @override
  int get hashCode {
    var hashCode = 0;
    hashCode = $hashCombine(hashCode, _self.commit.hashCode);
    hashCode = $hashCombine(hashCode, _self.parent.hashCode);
    hashCode = $hashCombine(hashCode, _self.author.hashCode);
    hashCode = $hashCombine(hashCode, _self.committer.hashCode);
    hashCode = $hashCombine(hashCode, $listEquality.hash(_self.message));
    return $hashFinish(hashCode);
  }
}

mixin _$Stash {
  Stash get _self => this as Stash;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Stash &&
          runtimeType == other.runtimeType &&
          _self.name == other.name &&
          _self.author == other.author &&
          _self.committer == other.committer &&
          $listEquality.equals(_self.message, other.message);
  @override
  int get hashCode {
    var hashCode = 0;
    hashCode = $hashCombine(hashCode, _self.name.hashCode);
    hashCode = $hashCombine(hashCode, _self.author.hashCode);
    hashCode = $hashCombine(hashCode, _self.committer.hashCode);
    hashCode = $hashCombine(hashCode, $listEquality.hash(_self.message));
    return $hashFinish(hashCode);
  }

  @override
  String toString() => (ClassToString('Stash')
        ..add('name', _self.name)
        ..add('author', _self.author)
        ..add('committer', _self.committer)
        ..add('message', _self.message))
      .toString();
}

mixin _$FileDto {
  FileDto get _self => this as FileDto;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileDto &&
          runtimeType == other.runtimeType &&
          $listEquality.equals(_self.status, other.status) &&
          $listEquality.equals(_self.paths, other.paths);
  @override
  int get hashCode {
    var hashCode = 0;
    hashCode = $hashCombine(hashCode, $listEquality.hash(_self.status));
    hashCode = $hashCombine(hashCode, $listEquality.hash(_self.paths));
    return $hashFinish(hashCode);
  }

  @override
  String toString() => (ClassToString('FileDto')
        ..add('status', _self.status)
        ..add('paths', _self.paths))
      .toString();
}

mixin _$BranchReferenceWithUpstream {
  BranchReferenceWithUpstream get _self => this as BranchReferenceWithUpstream;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BranchReferenceWithUpstream &&
          runtimeType == other.runtimeType &&
          _self.isHead == other.isHead &&
          _self.name == other.name &&
          _self.commit == other.commit &&
          _self.upstream == other.upstream &&
          $listEquality.equals(_self.message, other.message);
  @override
  int get hashCode {
    var hashCode = 0;
    hashCode = $hashCombine(hashCode, _self.isHead.hashCode);
    hashCode = $hashCombine(hashCode, _self.name.hashCode);
    hashCode = $hashCombine(hashCode, _self.commit.hashCode);
    hashCode = $hashCombine(hashCode, _self.upstream.hashCode);
    hashCode = $hashCombine(hashCode, $listEquality.hash(_self.message));
    return $hashFinish(hashCode);
  }

  @override
  String toString() => (ClassToString('BranchReferenceWithUpstream')
        ..add('isHead', _self.isHead)
        ..add('name', _self.name)
        ..add('commit', _self.commit)
        ..add('upstream', _self.upstream)
        ..add('message', _self.message))
      .toString();
}

mixin _$Mark {
  Mark get _self => this as Mark;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Mark &&
          runtimeType == other.runtimeType &&
          _self.hasHead == other.hasHead &&
          _self.remote == other.remote &&
          _self.local == other.local;
  @override
  int get hashCode {
    var hashCode = 0;
    hashCode = $hashCombine(hashCode, _self.hasHead.hashCode);
    hashCode = $hashCombine(hashCode, _self.remote.hashCode);
    hashCode = $hashCombine(hashCode, _self.local.hashCode);
    return $hashFinish(hashCode);
  }

  @override
  String toString() => (ClassToString('Mark')
        ..add('hasHead', _self.hasHead)
        ..add('remote', _self.remote)
        ..add('local', _self.local))
      .toString();
}
