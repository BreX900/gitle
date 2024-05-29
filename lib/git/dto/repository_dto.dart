import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:mek_data_class/mek_data_class.dart';

part 'repository_dto.g.dart';

@DataClass(changeable: true)
class RepositorySettingsDto with _$RepositorySettingsDto {
  static const IMap<String, RepositorySettingsDto> initialBin =
      IMapConst({}, ConfigMap(sort: true));

  final IList<String> protectedBranches;

  bool get hasBranchProtection => protectedBranches.isNotEmpty;

  const RepositorySettingsDto({
    this.protectedBranches = const IListConst([]),
  });

  static IMap<String, RepositorySettingsDto> fromBin(Object? data) {
    if (data is List) {
      return IMap.fromEntries(config: const ConfigMap(sort: true), data.map((e) {
        return MapEntry(e, const RepositorySettingsDto());
      }));
    }
    return IMap.fromJson(data! as Map<String, Object?>, (path) {
      return path! as String;
    }, (settings) {
      return RepositorySettingsDto.fromJson(settings! as Map<String, dynamic>);
    }).withConfig(const ConfigMap(sort: true));
  }

  static Object toBin(IMap<String, RepositorySettingsDto> data) {
    return data.toJson((e) => e, (e) => e.toJson());
  }

  Map<String, dynamic> toJson() {
    return {
      'protectedBranches': protectedBranches.unlockView,
    };
  }

  factory RepositorySettingsDto.fromJson(Map<String, dynamic> map) {
    return RepositorySettingsDto(
      protectedBranches: IList.fromJson(map['protectedBranches'], (e) => e! as String),
    );
  }
}
