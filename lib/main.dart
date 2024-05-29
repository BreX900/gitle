import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitle/git/clients/instances.dart';
import 'package:gitle/git/gitle_app.dart';
import 'package:logging/logging.dart';
import 'package:mek/mek.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Logger.root.reportRecords();
  Observers.attachAll();

  await Future.wait([
    Instances.register(),
    _initializeWindow(),
  ]);

  runApp(const ProviderScope(
    observers: [Observers.provider],
    child: GitleApp(),
  ));
}

Future<void> _initializeWindow() async {
  if (kIsWeb) return;

  await WindowManager.instance.ensureInitialized();
  // const targetSize = Size(128 * 9, 128 * 7);
  const targetSize = Size(128 * 10, 128 * 7.5);
  final size = await WindowManager.instance.getSize();
  if (size.width < targetSize.width || size.height < targetSize.height) {
    await WindowManager.instance.setSize(Size(
      max(size.width, targetSize.width),
      max(size.height, targetSize.height),
    ));
  }
  await WindowManager.instance.setMinimumSize(targetSize);
}
