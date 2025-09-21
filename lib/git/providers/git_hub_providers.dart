import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';
import 'package:gitle/common/logger.dart';
import 'package:gitle/git/clients/github.dart';
import 'package:gitle/git/clients/instances.dart';
import 'package:mek/mek.dart';
import 'package:mekart/mekart.dart';

abstract class GitHubProviders {
  static CachedBinStore<Map<String, dynamic>> get _bin => Instances.gitHubBin;

  static final token = Provider((ref) {
    ref.onDispose(Instances.gitHubTokenBin.onChanges.listen((vl) => ref.state = vl).cancel);
    return Instances.gitHubTokenBin.read();
  });

  static final shouldNotify = Provider((ref) {
    ref.onDispose(Instances.gitHubShouldNotifyBin.onChanges.listen((vl) => ref.state = vl).cancel);
    return Instances.gitHubShouldNotifyBin.read();
  });

  static final client = Provider((ref) {
    final token = ref.watch(GitHubProviders.token);
    if (token.isEmpty) return null;
    return GitHub(auth: Authentication.withToken(token));
  });

  static final notificationsListener = FutureProvider((ref) async {
    final shouldNotify = ref.watch(GitHubProviders.shouldNotify);
    if (!shouldNotify) return false;

    final gitHub = ref.watch(GitHubProviders.client);
    if (gitHub == null) return false;

    lg.config('Listening GitHub Notifications');
    final manager = NotificationsManager(gitHub);
    final subscription = await manager.listen(onChange: () => ref.invalidate(notifications));
    ref.onDispose(subscription.cancel);
    return true;
  });

  static final notifications = FutureProvider((ref) async {
    final gitHub = ref.watch(GitHubProviders.client);
    if (gitHub == null) return null;

    ref.invalidateWhenAppResume();

    return await gitHub.activity.listNotifications().toList();
  });

  static Future<void> update({String? token, bool? shouldNotify}) async {
    await _bin.write({
      if (token != null) 'token': token,
      if (shouldNotify != null) 'shouldNotify': shouldNotify,
    });
  }

  static Future<void> markAsRead(MutationRef ref, String threadId) async {
    final gitHub = ref.read(GitHubProviders.client)!;
    await gitHub.activity.markThreadRead(threadId);
    ref.invalidate(notifications);
  }

  static Future<void> markAllAsRead(MutationRef ref, None _) async {
    final gitHub = ref.read(GitHubProviders.client)!;
    await gitHub.activity.markNotificationsRead();
    ref.invalidate(notifications);
  }
}
