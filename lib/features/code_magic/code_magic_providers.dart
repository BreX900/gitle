import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitle/features/notifications/notifications_manager.dart';

abstract final class CodeMagicProviders {
  static final builds = StreamProvider((ref) {
    return NotificationsManager.instance.watchCodeMagicBuilds();
  });
}
