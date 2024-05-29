import 'package:flutter/foundation.dart';
import 'package:mek/mek.dart';

abstract final class Instances {
  static late final CachedBin<Map<String, dynamic>> gitHubBin;

  static CachedValueBin<String> get gitHubTokenBin =>
      CachedValueBin.fromMap(gitHubBin, 'token', '');
  static CachedValueBin<bool> get gitHubShouldNotifyBin =>
      CachedValueBin.fromMap(gitHubBin, 'shouldNotify', false);

  static Future<void> register() async {
    gitHubBin = await CachedBin.getInstance<Map<String, dynamic>>(Bin(
      name: resolveBinName('git_hub'),
      deserializer: (data) => (data as Map).cast<String, dynamic>(),
      fallbackData: const {},
    ));
  }

  static String resolveBinName(String name) => kIsWeb ? '__bins__#$name' : '__bins__/$name';
}
