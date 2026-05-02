import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mek_data_class/mek_data_class.dart';

part '../../generated/features/code_magic/code_magic_entities.g.dart';

@DataClass(copyable: true)
@JsonSerializable(createToJson: true, createFactory: true)
class CodeMagicConfigEntity with _$CodeMagicConfigEntity {
  final IList<CodeMagicJobEntity> jobs;

  const CodeMagicConfigEntity({this.jobs = const IList.empty()});

  factory CodeMagicConfigEntity.fromJson(Map<String, dynamic> map) =>
      _$CodeMagicConfigEntityFromJson(map);
  Map<String, dynamic> toJson() => _$CodeMagicConfigEntityToJson(this);
}

@DataClass()
@JsonSerializable(createToJson: true, createFactory: true)
class CodeMagicJobEntity with _$CodeMagicJobEntity {
  final String appId;
  final IList<String> workflowIds;

  const CodeMagicJobEntity({required this.appId, required this.workflowIds});

  factory CodeMagicJobEntity.fromJson(Map<String, dynamic> map) =>
      _$CodeMagicJobEntityFromJson(map);
  Map<String, dynamic> toJson() => _$CodeMagicJobEntityToJson(this);
}
