import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mek_data_class/mek_data_class.dart';

part '../../generated/features/repositories/repository_dto.g.dart';

@DataClass(changeable: true)
class RepositorySettingsDto with _$RepositorySettingsDto {
  static const IMap<String, RepositorySettingsDto> initialBin = IMapConst(
    {},
    ConfigMap(sort: true),
  );

  final IList<String> protectedBranches;
  // final CodeMagicConfigDto? codeMagic;

  bool get hasBranchProtection => protectedBranches.isNotEmpty;

  const RepositorySettingsDto({
    this.protectedBranches = const IListConst([]),
    // required this.codeMagic,
  });

  static IMap<String, RepositorySettingsDto> fromBin(Object? data) {
    return IMap.fromJson(
      data! as Map<String, Object?>,
      (path) => path! as String,
      (settings) => RepositorySettingsDto.fromJson(settings! as Map<String, dynamic>),
    ).withConfig(const ConfigMap(sort: true));
  }

  static Object toBin(IMap<String, RepositorySettingsDto> data) {
    return data.toJson((e) => e, (e) => e.toJson());
  }

  Map<String, dynamic> toJson() {
    return {'protectedBranches': protectedBranches.unlockView};
  }

  factory RepositorySettingsDto.fromJson(Map<String, dynamic> map) {
    return RepositorySettingsDto(
      protectedBranches: IList.fromJson(map['protectedBranches'], (e) => e! as String),
    );
  }
}

@DataClass(copyable: true)
@JsonSerializable(createFactory: true, createToJson: true)
class DashboardConfigDto with _$DashboardConfigDto {
  final String? groupUid;
  final IList<GroupDto> groups;

  int get groupIndex => groups.indexWhere((e) => e.uid == groupUid);

  GroupDto get group => groups[groupIndex];

  const DashboardConfigDto({required this.groupUid, required this.groups});

  factory DashboardConfigDto.fromJson(Map<String, dynamic> map) =>
      _$DashboardConfigDtoFromJson(map);
  Map<String, dynamic> toJson() => _$DashboardConfigDtoToJson(this);
}

@DataClass(copyable: true)
@JsonSerializable(createFactory: true, createToJson: true)
class GroupDto with _$GroupDto {
  final String? uid;
  final String? itemUid;
  final IList<String> items;

  const GroupDto({required this.uid, required this.itemUid, required this.items});

  int? get itemIndex {
    final index = items.indexOf(itemUid ?? '');
    return index == -1 ? null : index;
  }

  factory GroupDto.fromJson(Map<String, dynamic> map) => _$GroupDtoFromJson(map);
  Map<String, dynamic> toJson() => _$GroupDtoToJson(this);
}
