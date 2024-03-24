import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:github/github.dart';
import 'package:gitle/common/logger.dart';
import 'package:gitle/git/clients/github.dart';
import 'package:mek/mek.dart';

abstract class GitHubProviders {
  static final _bin = Bin<Map<String, dynamic>>(
    name: 'git_hub',
    deserializer: (data) => (data as Map).cast<String, dynamic>(),
  );

  static final token = Provider((ref) {
    ref.onDispose(_bin.stream
        .listen((values) => ref.state = ((values ?? {})['token'] as String?) ?? '')
        .cancel);
    return '';
  });

  static final shouldNotify = Provider((ref) {
    ref.onDispose(_shouldNotifyStream.listen((value) => ref.state = value).cancel);
    return false;
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

  static Stream<bool> get _shouldNotifyStream {
    return _bin.stream.map((values) {
      return ((values ?? {})['shouldNotify'] as bool?) ?? true;
    }).distinct();
  }
}
