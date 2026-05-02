import 'package:dio/dio.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/foundation.dart';
import 'package:gitle/common/logging_interceptor.dart';
import 'package:gitle/features/code_magic/code_magic_dto.dart';

const _apiToken = String.fromEnvironment('CODEMAGIC_API_TOKEN');
// const _appId = String.fromEnvironment('CODEMAGIC_APP_ID');

/// https://codemagic.io/api/v3/schema
class CodeMagicApi {
  static final CodeMagicApi instance = CodeMagicApi(_apiToken);

  final Dio _client;

  CodeMagicApi(String token)
    : _client = Dio(
        BaseOptions(baseUrl: 'https://api.codemagic.io', headers: {'x-auth-token': token}),
      )..interceptors.addAll([if (kDebugMode) const LoggingInterceptor()]);

  Future<IList<Application>> fetchApps() async {
    final response = await _client.get<Map<String, dynamic>>('/apps');
    return (response.data!['applications'] as List<dynamic>).map((data) {
      return Application.fromJson(data as Map<String, dynamic>);
    }).toIList();
  }

  Future<BuildsResponse> fetchBuilds({
    String? appId,
    String? workflowId,
    String? branch,
    String? tag,
  }) async {
    final response = await _client.get<Map<String, dynamic>>(
      '/builds',
      queryParameters: {
        if (appId != null) 'appId': appId,
        if (workflowId != null) 'workflowId': workflowId,
        if (branch != null) 'branch': branch,
        if (tag != null) 'tag': tag,
      },
    );
    return BuildsResponse.fromJson(response.data!);
  }

  Future<BuildSnapshot> fetchBuildSnapshot(String buildId) async {
    final response = await _client.get<Map<String, dynamic>>('/builds/$buildId');

    final build = response.data!['build'] as Map<String, dynamic>;

    return BuildSnapshot.fromJson(build);
  }

  Future<Map<String, dynamic>> startBuild({
    required String appId,
    required String workflowId,
    required String? branch,
    required String? tag,
  }) async {
    assert(branch != null || tag != null);
    final response = await _client.post<Map<String, dynamic>>(
      '/builds',
      data: {
        'appId': appId,
        'workflowId': workflowId,
        if (branch != null) 'branch': branch,
        if (tag != null) 'tag': tag,
      },
    );
    return response.data!;
  }

  Future<void> cancelBuild(String buildId) async {
    await _client.post<Map<String, dynamic>>('/builds/$buildId/cancel');
  }
}
