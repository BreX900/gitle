import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

class LoggingInterceptor extends Interceptor {
  const LoggingInterceptor();

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);

    unawaited(_handle(response));
  }

  Future<void> _handle(Response response) async {
    try {
      final segments = [
        'build',
        'logs',
        response.realUri.authority,
        ...response.realUri.pathSegments,
      ];

      final directory = Directory(segments.sublist(0, segments.length - 1).join('/'));
      if (!directory.existsSync()) await directory.create(recursive: true);

      final file = File('${directory.path}/${segments.last}.json');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(response.data));

      print('Saved to file://${file.path}');
    } catch (error, stackTrace) {
      Zone.current.handleUncaughtError(error, stackTrace);
    }
  }
}
