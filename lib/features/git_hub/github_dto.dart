import 'package:json_annotation/json_annotation.dart';

part '../../generated/features/git_hub/github_dto.g.dart';

@JsonEnum(alwaysCreate: true, fieldRename: FieldRename.pascal)
enum NotificationSubjectType {
  issue,
  pullRequest,
  checkSuite,
  release;

  factory NotificationSubjectType.fromJson(String source) =>
      $enumDecode(_$NotificationSubjectTypeEnumMap, source);
}
