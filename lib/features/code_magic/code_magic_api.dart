import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gitle/common/logging_interceptor.dart';
import 'package:gitle/features/code_magic/code_magic_dto.dart';

class CodeMagicApi {
  final Dio _client;

  CodeMagicApi(String token)
    : _client = Dio(
        BaseOptions(baseUrl: 'https://api.codemagic.io', headers: {'x-auth-token': token}),
      )..interceptors.addAll([if (kDebugMode) const LoggingInterceptor()]);

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

  Future<Map<String, dynamic>> startNewBuild({
    required String appId,
    required String workflowId,
    String? branch,
    String? tag,
  }) async {
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
}
