import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';
import 'package:gitle/common/logger.dart';
import 'package:gitle/git/clients/github.dart';
import 'package:gitle/git/clients/instances.dart';
import 'package:mekart/mekart.dart';

abstract class GitHubProviders {
  static CachedBin<Map<String, dynamic>> get _bin => Instances.gitHubBin;

  static final token = Provider((ref) {
    ref.onDispose(Instances.gitHubTokenBin.onChanges.listen((vl) => ref.state = vl).cancel);
    return Instances.gitHubTokenBin.read();
  });

  static final shouldNotify = Provider((ref) {
    ref.onDispose(Instances.gitHubShouldNotifyBin.onChanges.listen((vl) => ref.state = vl).cancel);
    return Instances.gitHubShouldNotifyBin.read();
  });

  static final notifications = FutureProvider((ref) async {
    final token = ref.watch(GitHubProviders.token);
    final shouldNotify = ref.watch(GitHubProviders.shouldNotify);
    if (token.isEmpty || !shouldNotify) return false;

    lg.config('Listening GitHub Notifications');
    final gitHub = GitHub(
      auth: Authentication.withToken(token),
    );
    ref.onDispose((await listenNotifications(gitHub)).cancel);
    return true;
  });

  static Future<void> update({String? token, bool? shouldNotify}) async {
    await _bin.write({
      if (token != null) 'token': token,
      if (shouldNotify != null) 'shouldNotify': shouldNotify,
    });
  }
}
