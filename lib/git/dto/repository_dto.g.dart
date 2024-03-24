// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: cast_nullable_to_non_nullable, avoid_annotating_with_dynamic

part of 'repository_dto.dart';

// **************************************************************************
// DataClassGenerator
// **************************************************************************

mixin _$RepositorySettingsDto {
  RepositorySettingsDto get _self => this as RepositorySettingsDto;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepositorySettingsDto &&
          runtimeType == other.runtimeType &&
          _self.protectedBranches == other.protectedBranches;
  @override
  int get hashCode {
    var hashCode = 0;
    hashCode = $hashCombine(hashCode, _self.protectedBranches.hashCode);
    return $hashFinish(hashCode);
  }

  @override
  String toString() =>
      (ClassToString('RepositorySettingsDto')..add('protectedBranches', _self.protectedBranches))
          .toString();
  RepositorySettingsDto change(void Function(_RepositorySettingsDtoChanges c) updates) =>
      (_RepositorySettingsDtoChanges._(_self)..update(updates)).build();
  _RepositorySettingsDtoChanges toChanges() => _RepositorySettingsDtoChanges._(_self);
}

class _RepositorySettingsDtoChanges {
  _RepositorySettingsDtoChanges._(RepositorySettingsDto dc)
      : protectedBranches = dc.protectedBranches;

  IList<String> protectedBranches;

  void update(void Function(_RepositorySettingsDtoChanges c) updates) => updates(this);

  RepositorySettingsDto build() => RepositorySettingsDto(
        protectedBranches: protectedBranches,
      );
}
