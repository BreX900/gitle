import 'dart:io';

import 'package:flutter/services.dart';

abstract final class Utils {
  static final String homeDirPath = Platform.isWindows
      ? '${Platform.environment['HOMEDRIVE']!}${Platform.environment['HOMEPATH']!}'
      : Platform.environment['HOME']!;

  static String removeHomePath(String path) {
    return path.replaceFirst(RegExp(r'\/Volumes\/[^/]+'), '').replaceFirst(homeDirPath, '~');
  }

  static Future<void> setClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
