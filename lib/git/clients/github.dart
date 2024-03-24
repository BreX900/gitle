import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:github/github.dart';
import 'package:gitle/common/logger.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

const _defaultPollInterval = Duration(seconds: 60);

extension NotificationsActivitityService on ActivityService {
  Stream<Notification> listNotificationsV2({
    bool all = false,
    bool participating = false,
    DateTime? since,
    DateTime? before,
  }) {
    return PaginationHelper(github).objects(
        'GET', '/notifications', (data) => Notification.fromJson(data! as Map<String, dynamic>),
        params: {
          'all': all,
          'participating': participating,
          if (since != null) 'since': since.toUtc().copyWith(microsecond: 0).toIso8601String(),
          if (before != null) 'before': before.toUtc().copyWith(microsecond: 0).toIso8601String(),
        });
  }

  Stream<Notification> onNotificationsChanges({
    bool all = false,
    bool participating = false,
  }) async* {
    String? lastModified;
    while (true) {
      final result = await _getNotifications(
        lastModified: lastModified,
        all: all,
        participating: participating,
      );

      lastModified = result.lastModified;

      for (final notification in result.notifications) {
        yield notification;
      }

      await Future.delayed(result.pollInterval);
    }
  }

  Future<_Result> _getNotifications({
    String? lastModified,
    bool all = false,
    bool participating = false,
    DateTime? since,
    DateTime? before,
  }) async {
    lg.info('${DateTime.now()} -> $lastModified');
    try {
      final response = await github.request('GET', '/notifications', headers: {
        'Accept': v3ApiMimeType,
        if (lastModified != null) 'If-Modified-Since': lastModified,
      }, params: {
        'all': all,
        'participating': participating,
        if (since != null) 'since': since.toUtc().copyWith(microsecond: 0).toIso8601String(),
        if (before != null) 'before': before.toUtc().copyWith(microsecond: 0).toIso8601String(),
      }, fail: (response) {
        if (response.statusCode == 304) {
          // ignore: only_throw_errors
          throw response;
        }
      });
      // final response = responses.single;
      // print(responses.map((e) => jsonEncode(e.headers)).toList());
      // print(responses.map((e) => e.body).toList());
      lg.finest(jsonEncode(response.headers));
      lg.finest(response.body);

      final data = response.body.isEmpty ? <dynamic>[] : jsonDecode(response.body) as List;
      return _Result(
        notifications:
            data.map((data) => Notification.fromJson(data as Map<String, dynamic>)).toList(),
        lastModified: response.headers['last-modified'],
        pollInterval: _getPollInterval(response.headers),
      );
    } on Response catch (response) {
      lg.finest(jsonEncode(response.headers));
      lg.finest(jsonEncode(response.body));

      return _Result(
        notifications: [],
        lastModified: response.headers['last-modified'] ?? lastModified,
        pollInterval: _getPollInterval(response.headers),
      );
    }
  }

  Duration _getPollInterval(Map<String, String> headers) {
    if (!headers.containsKey('x-poll-interval')) return _defaultPollInterval;
    return Duration(seconds: int.parse(headers['x-poll-interval']!));
  }
}

class _Result {
  final List<Notification> notifications;
  final String? lastModified;
  final Duration pollInterval;

  const _Result({
    required this.notifications,
    required this.lastModified,
    required this.pollInterval,
  });
}

Future<StreamSubscription<void>> listenNotifications(GitHub gitHub) async {
  final notificationsService = FlutterLocalNotificationsPlugin();

  await notificationsService.initialize(
    const InitializationSettings(
      macOS: DarwinInitializationSettings(),
    ),
    onDidReceiveBackgroundNotificationResponse: (response) =>
        lg.warning('listenNotifications.onDidReceiveBackgroundNotificationResponse'),
    onDidReceiveNotificationResponse: (response) async {
      final notification = Notification.fromJson(jsonDecode(response.payload!));
      await gitHub.activity.markThreadRead(notification.id!);

      final latestCommentUrl = notification.subject?.latestCommentUrl;
      if (latestCommentUrl == null || !latestCommentUrl.contains('/pulls/')) return;

      final pullResponse = await gitHub.requestJson('GET', latestCommentUrl);
      final pullRequest = PullRequest.fromJson(pullResponse);
      await launchUrl(Uri.parse(pullRequest.htmlUrl!));
    }, // Work!
  );

  final notificationsPlatformService = notificationsService
      .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()!;
  await notificationsPlatformService.requestPermissions();

  var notificationId = 0;
  final notificationIds = <String, int>{};

  // gitHub.activity.pollEventsForOrganization(name)
  return gitHub.activity.onNotificationsChanges().listen((notification) async {
    // print(jsonEncode(notification));

    await notificationsPlatformService.show(
      notificationIds.putIfAbsent(notification.id!, () => ++notificationId),
      notification.repository!.fullName,
      '${notification.subject!.type!}: ${notification.subject!.title!}',
      payload: jsonEncode(notification.toJson()),
    );
  });
}
