import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gitle/common/t_utils.dart';
import 'package:gitle/git/clients/git_extensions.dart';
import 'package:mek/mek.dart';

abstract final class AppUtils {
  static final String homeDirPath = Platform.isWindows
      ? '${Platform.environment['HOMEDRIVE']!}${Platform.environment['HOMEPATH']!}'
      : Platform.environment['HOME']!;

  static String removeHomePath(String path) {
    return path.replaceFirst(RegExp(r'\/Volumes\/[^/]+'), '').replaceFirst(homeDirPath, '~');
  }

  static Future<void> setClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  static void showErrorSnackBar(BuildContext context, Object error) {
    MekUtils.showSnackBarError(
      context: context,
      description: Text(TUtils.translateError(error)),
    );
  }
}

extension TranslatePushForce on PushForce {
  String translate() {
    return switch (this) {
      PushForce.enabled => 'Force Push',
      PushForce.enabledWithLease => 'Force Push With Lease',
    };
  }
}

class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRefresh;

  const ErrorView({super.key, required this.error, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return InfoView(
      onTap: onRefresh,
      icon: const Icon(Icons.error_outline),
      title: const Text('🤖 My n_m_ _s r_b_t! 🤖'),
      description: Text(TUtils.translateError(error)),
    );
  }
}
