import 'dart:async';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:github/github.dart';
import 'package:gitle/common/doubled_map.dart';
import 'package:gitle/features/code_magic/code_magic_service.dart';
import 'package:gitle/features/git_hub/git_hub_api_extensions.dart';
import 'package:gitle/features/git_hub/github_dto.dart';
import 'package:gitle/features/notifications/local_notification_manager.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationsManagerCore {
  FlutterLocalNotificationsPlugin get notificationsClient => FlutterLocalNotificationsPlugin();
  MacOSFlutterLocalNotificationsPlugin get notificationsMacOsClient =>
      notificationsClient.resolvePlatformSpecificImplementation()!;

  const NotificationsManagerCore();

  static var _notificationId = 0;

  int generateNotificationId() => _notificationId += 1;
}

class NotificationsManager extends NotificationsManagerCore with CodeMagicNotificationsManager {
  static const _githubCategory = 'github';
  static const _doneActionId = 'done';
  static const _readActionId = 'read';

  static final _notificationIds = DoubledMap<String, int>({});

  FlutterLocalNotificationsPlugin get _notificationsClient => FlutterLocalNotificationsPlugin();
  MacOSFlutterLocalNotificationsPlugin get _notificationsMacOsClient =>
      _notificationsClient.resolvePlatformSpecificImplementation()!;

  late GitHub githubClient;

  NotificationsManager._();

  static final instance = NotificationsManager._();

  Future<void> initialize({bool shouldRequestPermissions = true}) async {
    await _notificationsClient.initialize(
      settings: InitializationSettings(
        macOS: DarwinInitializationSettings(
          defaultPresentList: false, // Visible on notification center
          // ignore: avoid_redundant_argument_values
          defaultPresentBanner: true, // Visible as notification tile and disappear after time
          defaultPresentAlert: false, // Visible as notification tile and never disappear
          defaultPresentSound: false,
          defaultPresentBadge: false, // Not knows
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

    if (shouldRequestPermissions) await _notificationsMacOsClient.requestPermissions();
  }

  Future<StreamSubscription<void>> listen({required void Function() onChange}) async {
    // gitHub.activity.pollEventsForOrganization(name)
    return githubClient.activity
        .onNotificationsChanges()
        .doOnData((_) => onChange())
        .listen(_onReceiveRemoteNotification);
  }

  Future<void> handleLocalLocalNotification(NotificationResponse localNotification) async {
    if (_notificationIds.removeValue(localNotification.id ?? -1) == null) return;

    print('_> handleLocalLocalNotification ${localNotification.payload!}');

    final remoteNotification = Notification.fromJson(jsonDecode(localNotification.payload!));

    if (localNotification.actionId == _doneActionId) {
      await githubClient.activity.markThreadDone(remoteNotification.id!);
      return;
    }
    await githubClient.activity.markThreadRead(remoteNotification.id!);
    if (localNotification.actionId == _readActionId) return;

    final latestCommentUrl = remoteNotification.subject?.latestCommentUrl;
    if (latestCommentUrl != null && latestCommentUrl.contains('/pulls/')) {
      // _githubClient.pullRequests.get(slug, number)
      // https://docs.github.com/en/rest/pulls/pulls?apiVersion=2022-11-28#get-a-pull-request
      final pullResponse = await githubClient.requestJson(statusCode: 200, 'GET', latestCommentUrl);
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

    // print('_> _onReceiveRemoteNotification ${jsonEncode(remoteNotification)}');
    await _notificationsMacOsClient.show(
      id: _notificationIds.putIfAbsent(remoteNotification.id!, generateNotificationId),
      title: '${remoteNotification.repository!.name}: ${remoteNotification.subject!.type!}',
      body: remoteNotification.subject!.title,
      notificationDetails: const DarwinNotificationDetails(
        categoryIdentifier: _githubCategory,
        presentAlert: true,
      ),
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
