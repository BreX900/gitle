// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: cast_nullable_to_non_nullable, avoid_annotating_with_dynamic

part of 'repository_dto.dart';

// **************************************************************************
// DataClassGenerator
// **************************************************************************

mixin _$RepositorySettingsDto {
  RepositorySettingsDto get _self => this as RepositorySettingsDto;

  RepositorySettingsDto change(
    void Function(RepositorySettingsDtoChanges c) updates,
  ) => (toChanges()..update(updates)).build();

  RepositorySettingsDtoChanges toChanges() =>
      RepositorySettingsDtoChanges._(_self);

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
  String toString() => (ClassToString(
    'RepositorySettingsDto',
  )..add('protectedBranches', _self.protectedBranches)).toString();
}

class RepositorySettingsDtoChanges {
  RepositorySettingsDtoChanges._(this._original);

  final RepositorySettingsDto _original;

  late IList<String> protectedBranches = _original.protectedBranches;

  void update(void Function(RepositorySettingsDtoChanges c) updates) =>
      updates(this);

  RepositorySettingsDto build() {
    return RepositorySettingsDto(protectedBranches: protectedBranches);
  }
}

mixin _$DashboardConfigDto {
  DashboardConfigDto get _self => this as DashboardConfigDto;

  DashboardConfigDto copyWith({
    $Parameter<String?> groupUid = const Unspecified(),
    $Parameter<IList<GroupDto>> groups = const Unspecified(),
  }) {
    return DashboardConfigDto(
      groupUid: Unspecified.resolve(_self.groupUid, groupUid),
      groups: Unspecified.resolve(_self.groups, groups),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardConfigDto &&
          runtimeType == other.runtimeType &&
          _self.groupUid == other.groupUid &&
          _self.groups == other.groups;

  @override
  int get hashCode {
    var hashCode = 0;
    hashCode = $hashCombine(hashCode, _self.groupUid.hashCode);
    hashCode = $hashCombine(hashCode, _self.groups.hashCode);
    return $hashFinish(hashCode);
  }

  @override
  String toString() =>
      (ClassToString('DashboardConfigDto')
            ..add('groupUid', _self.groupUid)
            ..add('groups', _self.groups))
          .toString();
}

mixin _$GroupDto {
  GroupDto get _self => this as GroupDto;

  GroupDto copyWith({
    $Parameter<String?> uid = const Unspecified(),
    $Parameter<String?> itemUid = const Unspecified(),
    $Parameter<IList<String>> items = const Unspecified(),
  }) {
    return GroupDto(
      uid: Unspecified.resolve(_self.uid, uid),
      itemUid: Unspecified.resolve(_self.itemUid, itemUid),
      items: Unspecified.resolve(_self.items, items),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupDto &&
          runtimeType == other.runtimeType &&
          _self.uid == other.uid &&
          _self.itemUid == other.itemUid &&
          _self.items == other.items;

  @override
  int get hashCode {
    var hashCode = 0;
    hashCode = $hashCombine(hashCode, _self.uid.hashCode);
    hashCode = $hashCombine(hashCode, _self.itemUid.hashCode);
    hashCode = $hashCombine(hashCode, _self.items.hashCode);
    return $hashFinish(hashCode);
  }

  @override
  String toString() =>
      (ClassToString('GroupDto')
            ..add('uid', _self.uid)
            ..add('itemUid', _self.itemUid)
            ..add('items', _self.items))
          .toString();
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DashboardConfigDto _$DashboardConfigDtoFromJson(Map<String, dynamic> json) =>
    DashboardConfigDto(
      groupUid: json['groupUid'] as String?,
      groups: IList<GroupDto>.fromJson(
        json['groups'],
        (value) => GroupDto.fromJson(value as Map<String, dynamic>),
      ),
    );

Map<String, dynamic> _$DashboardConfigDtoToJson(DashboardConfigDto instance) =>
    <String, dynamic>{
      'groupUid': instance.groupUid,
      'groups': instance.groups.toJson((value) => value),
    };

GroupDto _$GroupDtoFromJson(Map<String, dynamic> json) => GroupDto(
  uid: json['uid'] as String?,
  itemUid: json['itemUid'] as String?,
  items: IList<String>.fromJson(json['items'], (value) => value as String),
);

Map<String, dynamic> _$GroupDtoToJson(GroupDto instance) => <String, dynamic>{
  'uid': instance.uid,
  'itemUid': instance.itemUid,
  'items': instance.items.toJson((value) => value),
};
