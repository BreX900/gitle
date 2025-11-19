import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:github/github.dart';
import 'package:gitle/common/logger.dart';
import 'package:gitle/git/clients/github.dart';
import 'package:gitle/git/clients/instances.dart';

@pragma('vm:entry-point')
Future<void> onReceiveLocalBackgroundNotification(NotificationResponse localNotification) async {
  lg.warning('onReceiveLocalBackgroundNotification');

  final token = Instances.gitHubTokenBin.read();
  if (token.isEmpty) return;

  NotificationsManager.instance.githubClient = GitHub(auth: Authentication.withToken(token));
  await NotificationsManager.instance.initialize(shouldRequestPermissions: false);
  await NotificationsManager.instance.handleLocalLocalNotification(localNotification);
}
