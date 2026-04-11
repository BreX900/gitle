import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:gitle/features/code_magic/code_magic_entities.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mek_data_class/mek_data_class.dart';

part '../../generated/features/repositories/repository_entity.g.dart';

@DataClass(copyable: true)
@JsonSerializable(createFactory: true, createToJson: true)
class RepositoryConfigEntity with _$RepositoryConfigEntity {
  static const IMap<String, RepositoryConfigEntity> initialBin = IMapConst(
    {},
    ConfigMap(sort: true),
  );

  final IList<String> protectedBranches;
  final CodeMagicConfigEntity codeMagic;

  bool get hasBranchProtection => protectedBranches.isNotEmpty;

  const RepositoryConfigEntity({
    this.protectedBranches = const IListConst([]),
    this.codeMagic = const CodeMagicConfigEntity(),
  });

  static IMap<String, RepositoryConfigEntity> fromBin(Object? data) {
    return IMap.fromJson(
      data! as Map<String, Object?>,
      (path) => path! as String,
      (settings) => RepositoryConfigEntity.fromJson(settings! as Map<String, dynamic>),
    ).withConfig(const ConfigMap(sort: true));
  }

  static Object toBin(IMap<String, RepositoryConfigEntity> data) {
    return data.toJson((e) => e, (e) => e.toJson());
  }

  factory RepositoryConfigEntity.fromJson(Map<String, dynamic> map) =>
      _$RepositoryConfigEntityFromJson(map);
  Map<String, dynamic> toJson() => _$RepositoryConfigEntityToJson(this);
}
