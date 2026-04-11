import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mek_data_class/mek_data_class.dart';

part '../../generated/features/dashboard/dashboard_config_entity.g.dart';

@DataClass(copyable: true)
@JsonSerializable(createFactory: true, createToJson: true)
class DashboardConfigEntity with _$DashboardConfigEntity {
  final String? groupUid;
  final IList<DashboardGroupEntity> groups;

  int get groupIndex => groups.indexWhere((e) => e.uid == groupUid);

  DashboardGroupEntity get group => groups[groupIndex];

  const DashboardConfigEntity({required this.groupUid, required this.groups});

  factory DashboardConfigEntity.fromJson(Map<String, dynamic> map) =>
      _$DashboardConfigEntityFromJson(map);
  Map<String, dynamic> toJson() => _$DashboardConfigEntityToJson(this);
}

@DataClass(copyable: true)
@JsonSerializable(createFactory: true, createToJson: true)
class DashboardGroupEntity with _$DashboardGroupEntity {
  final String? uid;
  final String? itemUid;
  final IList<String> items;

  const DashboardGroupEntity({required this.uid, required this.itemUid, required this.items});

  int? get itemIndex {
    final index = items.indexOf(itemUid ?? '');
    return index == -1 ? null : index;
  }

  factory DashboardGroupEntity.fromJson(Map<String, dynamic> map) =>
      _$DashboardGroupEntityFromJson(map);
  Map<String, dynamic> toJson() => _$DashboardGroupEntityToJson(this);
}
