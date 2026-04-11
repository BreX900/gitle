import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitle/features/notifications/notifications_manager.dart';

abstract final class CodeMagicProviders {
  static final builds = StreamProvider((ref) {
    return NotificationsManager.instance.watchCodeMagicBuilds();
  });
}

class CodeMagicConfigDto {
  final String repositoryPath;
  final String appId;
  final IList<CodeMagicWorkflowDto> workflows;

  const CodeMagicConfigDto({
    required this.repositoryPath,
    required this.appId,
    required this.workflows,
  });
}

class CodeMagicWorkflowDto {
  final String name;
  final IList<String> ids;

  const CodeMagicWorkflowDto({required this.name, required this.ids});
}
