import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mek/mek.dart';

abstract class T {
  static void showSnackBarError(BuildContext context, ErrorData data) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final backgroundColor = colors.errorContainer;
    final foregroundColor = colors.onErrorContainer;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      padding: const EdgeInsets.fromLTRB(0.0, 14.0, 0.0, 14.0),
      duration: const Duration(minutes: 1),
      showCloseIcon: true,
      closeIconColor: foregroundColor,
      backgroundColor: backgroundColor,
      content: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(Icons.error_outline, color: foregroundColor),
          ),
          Text(translateError(data.error), style: TextStyle(color: foregroundColor)),
        ],
      ),
    ));
  }

  static String translateError(Object error) {
    if (error is ProcessException) {
      return '${error.executable} ${error.arguments.join(' ')}\n${error.errorCode}: ${error.message}';
    }
    return '$error';
  }
}
