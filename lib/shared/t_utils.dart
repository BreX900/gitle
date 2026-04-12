import 'dart:io';

import 'package:mek/mek.dart';

abstract final class TUtils {
  static String translateError(Object error) {
    if (error is ProcessException) {
      return '${error.executable} ${error.arguments.join(' ')}\n${error.errorCode}: ${error.message}';
    } else if (error is TextualError) {
      return error.message;
    }
    return '$error';
  }
}
