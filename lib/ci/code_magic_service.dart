import 'dart:async';

import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:gitle/ci/code_magic_api.dart';
import 'package:gitle/common/logger.dart';
import 'package:gitle/git/clients/github.dart';

const _apiToken = String.fromEnvironment('CODEMAGIC_API_TOKEN');
// const _appId = String.fromEnvironment('CODEMAGIC_APP_ID');

mixin CodeMagicNotificationsManager on NotificationsManagerCore {
  static final _appsNotificationIds = <String, int>{};

  final _codeMagicApi = CodeMagicApi(_apiToken);

  final _pendingAppIds = <String>{};

  Future<void> watchCodeMagicBuilds() async {
    while (true) {
      lg.info('${DateTime.now()} Checking CodeMagic builds...');
      try {
        await _handle();
      } catch (error, stackTrace) {
        Zone.current.handleUncaughtError(error, stackTrace);
      }

      await Future<void>.delayed(
        _pendingAppIds.isNotEmpty ? const Duration(seconds: 30) : const Duration(minutes: 2),
      );
    }
  }

  Future<void> _handle() async {
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
      lg.info('${_pendingAppIds.length} New App Building "${app.appName}"...');

      // notificationsMacOsClient.getActiveNotifications();

      await notificationsMacOsClient.show(
        _appsNotificationIds.putIfAbsent(appId, generateNotificationId),
        '🚜 ${app.appName}',
        '$buildCount builds is in pending...',
        notificationDetails: const DarwinNotificationDetails(
          categoryIdentifier: 'codemagic-builds',
        ),
      );
    }

    for (final appId in finishedAppIds) {
      final app = response.applications.firstWhere((e) => e.id == appId);

      _pendingAppIds.remove(appId);
      lg.info('${_pendingAppIds.length} Finished App Build "${app.appName}"!');

      await notificationsMacOsClient.show(
        _appsNotificationIds.putIfAbsent(appId, generateNotificationId),
        '✅ ${app.appName}',
        'All builds is completed!',
        notificationDetails: const DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
          categoryIdentifier: 'codemagic-builds',
        ),
      );
    }
  }
}

extension<K, V> on Map<K, V> {
  Map<K, V> where(bool Function(K key, V value) predicate) =>
      Map.fromEntries(entries.where((entry) => predicate(entry.key, entry.value)));
}
