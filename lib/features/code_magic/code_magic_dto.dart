import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:json_annotation/json_annotation.dart';

part '../../generated/features/code_magic/code_magic_dto.g.dart';

@JsonSerializable(createFactory: true)
class BuildsResponse {
  final IList<Application> applications;
  final IList<Build> builds;

  const BuildsResponse({required this.applications, required this.builds});

  factory BuildsResponse.fromJson(Map<String, dynamic> map) => _$BuildsResponseFromJson(map);
}

@JsonSerializable(createFactory: true)
class Application {
  @JsonKey(name: '_id')
  final String id;
  final String appName;

  const Application({required this.id, required this.appName});

  factory Application.fromJson(Map<String, dynamic> map) => _$ApplicationFromJson(map);
}

@JsonSerializable(createFactory: true)
class Build {
  @JsonKey(name: '_id')
  final String id;
  final String appId;
  final String? workflowId;
  final String? branch;
  final String? tag;
  final BuildStatus status;
  final String? version;

  const Build({
    required this.id,
    required this.appId,
    required this.workflowId,
    required this.branch,
    required this.tag,
    required this.status,
    required this.version,
  });

  factory Build.fromJson(Map<String, dynamic> map) => _$BuildFromJson(map);
}

@JsonSerializable(createFactory: true)
class BuildSnapshot {
  @JsonKey(name: '_id')
  final String id;
  final BuildStatus status;
  final String? workflowId;

  const BuildSnapshot({required this.id, required this.status, required this.workflowId});

  factory BuildSnapshot.fromJson(Map<String, dynamic> map) => _$BuildSnapshotFromJson(map);
}

enum BuildStatus {
  queued,
  preparing,
  skipped,
  fetching,
  building,
  publishing,
  canceled,
  finishing,
  failed,
  finished;

  bool get isPending {
    return switch (this) {
      BuildStatus.queued => true,
      BuildStatus.preparing => true,
      BuildStatus.skipped => false,
      BuildStatus.fetching => true,
      BuildStatus.building => true,
      BuildStatus.publishing => true,
      BuildStatus.canceled => false,
      BuildStatus.finishing => true,
      BuildStatus.failed => false,
      BuildStatus.finished => false,
    };
  }

  factory BuildStatus.fromJson(String source) {
    return BuildStatus.values.firstWhere((e) => e.name == source);
  }
}
