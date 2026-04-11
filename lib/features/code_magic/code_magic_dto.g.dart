// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: cast_nullable_to_non_nullable, avoid_annotating_with_dynamic

part of 'code_magic_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BuildsResponse _$BuildsResponseFromJson(Map<String, dynamic> json) =>
    BuildsResponse(
      applications: IList<Application>.fromJson(
        json['applications'],
        (value) => Application.fromJson(value as Map<String, dynamic>),
      ),
      builds: IList<Build>.fromJson(
        json['builds'],
        (value) => Build.fromJson(value as Map<String, dynamic>),
      ),
    );

Application _$ApplicationFromJson(Map<String, dynamic> json) =>
    Application(id: json['_id'] as String, appName: json['appName'] as String);

Build _$BuildFromJson(Map<String, dynamic> json) => Build(
  id: json['_id'] as String,
  appId: json['appId'] as String,
  workflowId: json['workflowId'] as String?,
  branch: json['branch'] as String?,
  tag: json['tag'] as String?,
  status: BuildStatus.fromJson(json['status'] as String),
  version: json['version'] as String?,
);

BuildSnapshot _$BuildSnapshotFromJson(Map<String, dynamic> json) =>
    BuildSnapshot(
      id: json['_id'] as String,
      status: BuildStatus.fromJson(json['status'] as String),
      workflowId: json['workflowId'] as String?,
    );
