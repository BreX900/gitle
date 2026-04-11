import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:json_annotation/json_annotation.dart';

part '../../generated/features/code_magic/code_magic_entities.g.dart';

@JsonSerializable(createToJson: true, createFactory: true)
class CodeMagicConfigEntity {
  final String repositoryPath;
  final String appId;
  final IList<CodeMagicWorkflowEntity> workflows;

  const CodeMagicConfigEntity({
    required this.repositoryPath,
    required this.appId,
    required this.workflows,
  });

  factory CodeMagicConfigEntity.fromJson(Map<String, dynamic> map) =>
      _$CodeMagicConfigEntityFromJson(map);
  Map<String, dynamic> toJson() => _$CodeMagicConfigEntityToJson(this);
}

@JsonSerializable(createToJson: true, createFactory: true)
class CodeMagicWorkflowEntity {
  final String name;
  final IList<String> ids;

  const CodeMagicWorkflowEntity({required this.name, required this.ids});

  factory CodeMagicWorkflowEntity.fromJson(Map<String, dynamic> map) =>
      _$CodeMagicWorkflowEntityFromJson(map);
  Map<String, dynamic> toJson() => _$CodeMagicWorkflowEntityToJson(this);
}
