import 'package:flutter/foundation.dart';
import 'package:mekart/mekart.dart';
import 'package:path_provider/path_provider.dart';

abstract final class Instances {
  static late final CachedBin<Map<String, dynamic>> gitHubBin;

  static CachedValueBin<String> get gitHubTokenBin =>
      CachedValueBin.fromMap(gitHubBin, 'token', '');
  static CachedValueBin<bool> get gitHubShouldNotifyBin =>
      CachedValueBin.fromMap(gitHubBin, 'shouldNotify', false);

  static Future<void> register() async {
    BinEngine.instance = _BinEngine();
    gitHubBin = await CachedBin.getInstance<Map<String, dynamic>>(Bin(
      name: resolveBinName('git_hub'),
      deserializer: (data) => (data as Map).cast<String, dynamic>(),
      fallbackData: const {},
    ));
  }

  static String resolveBinName(String name) => kIsWeb ? '__bins__#$name' : '__bins__/$name';
}

class _BinEngine extends BinEngineBase {
  @override
  Future<String?> getDirectoryPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
}
