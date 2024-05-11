import 'dart:io';

import 'package:flutter/material.dart' as w;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class Utils {
  static final String homeDirPath = Platform.isWindows
      ? '${Platform.environment['HOMEDRIVE']!}${Platform.environment['HOMEPATH']!}'
      : Platform.environment['HOME']!;

  static String removeHomePath(String path) {
    return path.replaceFirst(RegExp(r'\/Volumes\/[^/]+'), '').replaceFirst(homeDirPath, '~');
  }

  static Future<void> showMenu({
    required BuildContext context,
    Offset offset = Offset.zero,
    required List<PopupMenuEntry<VoidCallback>> items,
  }) async {
    final overlay = Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final renderBox = context.findRenderObject()! as RenderBox;

    final startBoxOffset = renderBox.localToGlobal(offset, ancestor: overlay);
    final endBoxOffset =
        renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero), ancestor: overlay);

    final position = RelativeRect.fromLTRB(
      startBoxOffset.dx,
      startBoxOffset.dy,
      endBoxOffset.dx,
      endBoxOffset.dy,
    );

    final callback = await w.showMenu<VoidCallback>(
      context: context,
      position: position,
      constraints: const BoxConstraints(minHeight: 32.0, minWidth: 128.0),
      items: items,
    );

    callback?.call();
  }

  static Future<void> setClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
