import 'package:flutter/foundation.dart';
import 'package:mekart/mekart.dart';
import 'package:path_provider/path_provider.dart';

extension on BinSession {
  BinStore<Map<String, dynamic>> get gitHub => BinStore(
        session: this,
        name: 'git_hub.json',
        deserializer: (data) => (data as Map).cast<String, dynamic>(),
        fallbackData: const {},
      );
}

abstract final class Instances {
  static final BinConnection bin = BinConnection(_BinEngine());
  static late final CachedBinStore<Map<String, dynamic>> gitHubBin;

  static CachedValueBinStore<String> get gitHubTokenBin =>
      CachedValueBinStore.fromMap(gitHubBin, 'token', '');

  static CachedValueBinStore<bool> get gitHubShouldNotifyBin =>
      CachedValueBinStore.fromMap(gitHubBin, 'shouldNotify', false);

  static Future<void> register() async {
    gitHubBin = await CachedBinStore.getInstance<Map<String, dynamic>>(bin.gitHub);
  }

  static String resolveBinName(String name) => kIsWeb ? '__bins__#$name' : '__bins__/$name';
}

class _BinEngine extends BinEngineBase {
  @override
  Future<String?> getDirectoryPath() async {
    final directory = await getApplicationSupportDirectory();
    return directory.path;
  }
}
