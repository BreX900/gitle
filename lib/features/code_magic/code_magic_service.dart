import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gitle/common/logger.dart';
import 'package:gitle/features/code_magic/code_magic_api.dart';
import 'package:gitle/features/code_magic/code_magic_dto.dart';
import 'package:gitle/features/notifications/notifications_manager.dart';

mixin CodeMagicNotificationsManager on NotificationsManagerCore {
  static final _appsNotificationIds = <String, int>{};

  CodeMagicApi get _codeMagicApi => CodeMagicApi.instance;

  final _pendingAppIds = <String>{};

  Stream<BuildsResponse> watchCodeMagicBuilds() async* {
    while (true) {
      lg.info('${DateTime.now()} Checking CodeMagic builds...');
      try {
        yield await _handle();
      } catch (error, stackTrace) {
        Zone.current.handleUncaughtError(error, stackTrace);
      }

      await Future<void>.delayed(
        _pendingAppIds.isNotEmpty ? const Duration(seconds: 30) : const Duration(minutes: 2),
      );
    }
  }

  Future<BuildsResponse> _handle() async {
    final response = await _codeMagicApi.fetchBuilds();
    final builds = response.builds
        .where((e) => e.status.isPending)
        .groupListsBy((e) => e.appId)
        .map((appId, builds) => MapEntry(appId, builds.length))
        .toIMap();

    final startedAppIds = builds.where((appId, _) => !_pendingAppIds.contains(appId));
    final finishedAppIds = _pendingAppIds.where((appId) => !builds.containsKey(appId));

    for (final MapEntry(key: appId, value: buildCount) in startedAppIds.entries) {
      final app = response.applications.firstWhere((e) => e.id == appId);

      _pendingAppIds.add(appId);
      lg.info('${_pendingAppIds.length} New App Building "${app.name}"...');

      // notificationsMacOsClient.getActiveNotifications();

      await notificationsMacOsClient.show(
        id: _appsNotificationIds.putIfAbsent(appId, generateNotificationId),
        title: '🚜 ${app.name}',
        body: '$buildCount builds is in pending...',
        notificationDetails: const DarwinNotificationDetails(
          categoryIdentifier: 'codemagic-builds',
        ),
      );
    }

    for (final appId in finishedAppIds) {
      final app = response.applications.firstWhere((e) => e.id == appId);

      _pendingAppIds.remove(appId);
      lg.info('${_pendingAppIds.length} Finished App Build "${app.name}"!');

      await notificationsMacOsClient.show(
        id: _appsNotificationIds.putIfAbsent(appId, generateNotificationId),
        title: '✅ ${app.name}',
        body: 'All builds is completed!',
        notificationDetails: const DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
          categoryIdentifier: 'codemagic-builds',
        ),
      );
    }

    return response;
  }
}
