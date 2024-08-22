import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mek/mek.dart';

abstract class T {
  static void showSnackBarError(BuildContext context, ErrorData data) {
    MekUtils.showSnackBarError(
      context: context,
      description: Text(translateError(data.error)),
    );
  }

  static String translateError(Object error) {
    if (error is ProcessException) {
      return '${error.executable} ${error.arguments.join(' ')}\n${error.errorCode}: ${error.message}';
    }
    return '$error';
  }
}
