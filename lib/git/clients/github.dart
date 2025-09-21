import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:github/github.dart';
import 'package:gitle/common/logger.dart';
import 'package:gitle/git/clients/local_notification_manager.dart';
import 'package:gitle/git/dto/github_dto.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';

const _defaultPollInterval = Duration(seconds: 60);

extension NotificationsActivitityService on ActivityService {
  // Stream<Notification> listNotificationsV2({
  //   bool all = false,
  //   bool participating = false,
  //   DateTime? since,
  //   DateTime? before,
  // }) {
  //   return PaginationHelper(github).objects(
  //     'GET',
  //     '/notifications',
  //     (data) => Notification.fromJson(data! as Map<String, dynamic>),
  //     params: {
  //       'all': all,
  //       'participating': participating,
  //       if (since != null) 'since': since.toUtc().copyWith(microsecond: 0).toIso8601String(),
  //       if (before != null) 'before': before.toUtc().copyWith(microsecond: 0).toIso8601String(),
  //     },
  //   );
  // }

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
      final response = await github.request(
        'GET',
        '/notifications',
        headers: {
          'Accept': v3ApiMimeType,
          if (lastModified != null) 'If-Modified-Since': lastModified,
        },
        params: {
          'all': all,
          'participating': participating,
          if (since != null) 'since': since.toUtc().copyWith(microsecond: 0).toIso8601String(),
          if (before != null) 'before': before.toUtc().copyWith(microsecond: 0).toIso8601String(),
        },
        fail: (response) {
          if (response.statusCode == 304) {
            // ignore: only_throw_errors
            throw response;
          }
        },
      );
      // final response = responses.single;
      // print(responses.map((e) => jsonEncode(e.headers)).toList());
      // print(responses.map((e) => e.body).toList());
      // lg.finest(jsonEncode(response.headers));
      // lg.finest(response.body);

      final data = response.body.isEmpty ? <dynamic>[] : jsonDecode(response.body) as List;
      return _Result(
        notifications: data
            .map((data) => Notification.fromJson(data as Map<String, dynamic>))
            .toList(),
        lastModified: response.headers['last-modified'],
        pollInterval: _getPollInterval(response.headers),
      );
    } on Response catch (response) {
      // lg.finest(jsonEncode(response.headers));
      // lg.finest(jsonEncode(response.body));

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

class NotificationsManager {
  static const _githubCategory = 'github';
  static const _doneActionId = 'done';
  static const _readActionId = 'read';

  static var _notificationId = 0;
  static final _notificationIds = <String, int>{};

  FlutterLocalNotificationsPlugin get _notificationsClient => FlutterLocalNotificationsPlugin();
  MacOSFlutterLocalNotificationsPlugin get _notificationsMacOsClient =>
      _notificationsClient.resolvePlatformSpecificImplementation()!;
  final GitHub _githubClient;

  const NotificationsManager(this._githubClient);

  Future<StreamSubscription<void>> listen({required void Function() onChange}) async {
    await _notificationsClient.initialize(
      InitializationSettings(
        macOS: DarwinInitializationSettings(
          notificationCategories: [
            DarwinNotificationCategory(
              _githubCategory,
              options: {DarwinNotificationCategoryOption.customDismissAction},
              actions: [
                DarwinNotificationAction.plain(_readActionId, 'Read'),
                DarwinNotificationAction.plain(
                  _doneActionId,
                  'Done',
                  options: {DarwinNotificationActionOption.destructive},
                ),
              ],
            ),
          ],
        ),
      ),
      onDidReceiveBackgroundNotificationResponse: onReceiveLocalBackgroundNotification,
      onDidReceiveNotificationResponse: handleLocalLocalNotification, // Work!
    );

    await _notificationsMacOsClient.requestPermissions();

    // gitHub.activity.pollEventsForOrganization(name)
    return _githubClient.activity
        .onNotificationsChanges()
        .doOnData((_) => onChange())
        .listen(_onReceiveRemoteNotification);
  }

  Future<void> handleLocalLocalNotification(NotificationResponse localNotification) async {
    print('_> handleLocalLocalNotification ${localNotification.payload!}');

    final remoteNotification = Notification.fromJson(jsonDecode(localNotification.payload!));

    if (localNotification.actionId == _doneActionId) {
      await _githubClient.activity.markThreadDone(remoteNotification.id!);
      return;
    }
    await _githubClient.activity.markThreadRead(remoteNotification.id!);
    if (localNotification.actionId == _readActionId) return;

    final latestCommentUrl = remoteNotification.subject?.latestCommentUrl;
    if (latestCommentUrl != null && latestCommentUrl.contains('/pulls/')) {
      // _githubClient.pullRequests.get(slug, number)
      // https://docs.github.com/en/rest/pulls/pulls?apiVersion=2022-11-28#get-a-pull-request
      final pullResponse = await _githubClient.requestJson(
        statusCode: 200,
        'GET',
        latestCommentUrl,
      );
      print('_> PullRequest ${jsonEncode(pullResponse)}');
      final pullRequest = PullRequest.fromJson(pullResponse);
      if (pullRequest.htmlUrl case final htmlUrl?) {
        await launchUrl(Uri.parse(htmlUrl));
        return;
      }
    }
    final path = switch (NotificationSubjectType.fromJson(remoteNotification.subject!.type!)) {
      NotificationSubjectType.checkSuite => '/actions',
      NotificationSubjectType.issue => '/issues',
      NotificationSubjectType.pullRequest => '/pulls',
      NotificationSubjectType.release => '/releases',
    };
    await launchUrl(Uri.parse('${remoteNotification.repository!.htmlUrl}$path'));
  }

  Future<void> _onReceiveRemoteNotification(Notification remoteNotification) async {
    if (_notificationIds.containsKey(remoteNotification.id)) return;
    if (!_checkShow(remoteNotification.subject)) return;

    print('_> _onReceiveRemoteNotification ${jsonEncode(remoteNotification)}');
    await _notificationsMacOsClient.show(
      _notificationIds.putIfAbsent(remoteNotification.id!, () => ++_notificationId),
      '${remoteNotification.repository!.name}: ${remoteNotification.subject!.type!}',
      remoteNotification.subject!.title,
      notificationDetails: const DarwinNotificationDetails(categoryIdentifier: _githubCategory),
      payload: jsonEncode(remoteNotification.toJson()),
    );
  }

  bool _checkShow(NotificationSubject? subject) {
    if (subject == null) return true;
    return switch (NotificationSubjectType.fromJson(subject.type!)) {
      NotificationSubjectType.issue => false,
      NotificationSubjectType.checkSuite => subject.title?.contains('failed') ?? false,
      NotificationSubjectType.pullRequest => true,
      NotificationSubjectType.release => false,
    };
  }

  // https://github.com/stripe/stripe-terminal-ios/releases/tag/4.7.0?notification_referrer_id=NT_kwDOBEYMobQxODY5NjkzNDYzMDo3MTY5OTYxNw
}

extension on ActivityService {
  /// Marks a thread as "done".
  ///
  /// Marking a thread as "done" is equivalent to marking a notification in your notification inbox
  /// on GitHub as done: https://github.com/notifications.
  /// API docs: https://developer.github.com/v3/activity/notifications/#mark-a-thread-as-done
  Future<bool> markThreadDone(String threadId) async {
    final response = await github.request(
      statusCode: 200,
      'DELETE',
      '/notifications/threads/$threadId',
    );
    return response.statusCode == StatusCodes.RESET_CONTENT;
  }
}
