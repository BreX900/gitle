import 'package:flutter/material.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/features/code_magic/code_magic_dto.dart';
import 'package:gitle/features/code_magic/code_magic_providers.dart';
import 'package:gitle/git/models/repository_model.dart';
import 'package:gitle/git/providers/git_hub_providers.dart';
import 'package:gitle/git/providers/repositories_providers.dart';
import 'package:mek/mek.dart';

class RepositorySettingsDrawer extends SourceConsumerStatefulWidget {
  final RepositoryModel repository;

  const RepositorySettingsDrawer({super.key, required this.repository});

  @override
  SourceConsumerState<RepositorySettingsDrawer> createState() => _RepositorySettingsDrawerState();
}

class _RepositorySettingsDrawerState extends SourceConsumerState<RepositorySettingsDrawer> {
  late final _toggleBranchProtection = ref.mutation((ref, bool isEnabled) async {
    await RepositoriesProviders.toggleBranchesProtection(ref, isEnabled: isEnabled);
  }, onError: (_, error) => AppUtils.showErrorSnackBar(context, error));

  late final _markAsRead = ref.mutation(
    GitHubProviders.markAsRead,
    onError: (_, error) => AppUtils.showErrorSnackBar(context, error),
  );

  late final _markAllAsRead = ref.mutation(
    GitHubProviders.markAllAsRead,
    onError: (_, error) => AppUtils.showErrorSnackBar(context, error),
  );

  Widget _buildCodeMagicBuilds() {
    final buildsState = ref.watch(CodeMagicProviders.builds);

    return Column(
      children: [
        ParagraphTile(title: Text('CodeMagic Builds')),
        Expanded(
          child: buildsState.buildWhen(
            loading: CircularProgressIndicator.new,
            error: (_, _) => const SizedBox.shrink(),
            data: (response) => ListView.builder(
              itemCount: response.builds.length,
              itemBuilder: (context, index) {
                final build = response.builds[index];
                final app = response.applications.firstWhere((e) => e.id == build.appId);

                return ListTile(
                  leading: Tooltip(
                    message: build.status.name,
                    child: switch (build.status) {
                      BuildStatus.queued => const Icon(Icons.pending),
                      BuildStatus.preparing => const Icon(Icons.build, color: Colors.yellow),
                      BuildStatus.skipped => const Icon(Icons.skip_next, color: Colors.grey),
                      BuildStatus.fetching => const Icon(Icons.download, color: Colors.yellow),
                      BuildStatus.building => const Icon(Icons.build, color: Colors.yellow),
                      BuildStatus.publishing => const Icon(Icons.upload, color: Colors.yellow),
                      BuildStatus.canceled => const Icon(Icons.delete, color: Colors.grey),
                      BuildStatus.failed => const Icon(Icons.bug_report, color: Colors.red),
                      BuildStatus.finishing => const Icon(
                        Icons.cleaning_services,
                        color: Colors.yellow,
                      ),
                      BuildStatus.finished => const Icon(Icons.check_circle, color: Colors.green),
                    },
                  ),
                  title: Text('${app.appName} - Version: ${build.version}'),
                  subtitle: Text(
                    'From: ${build.tag ?? build.branch ?? '?'} - WorkflowId: ${build.workflowId ?? '-'}',
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotifications() {
    final notifications = ref.watch(GitHubProviders.notifications);

    return Column(
      children: [
        ParagraphTile(title: Text('GitHub Notifications')),
        TextButton(onPressed: () => _markAllAsRead(none), child: const Text('Mark All As Read')),
        Expanded(
          child: notifications.buildWhen(
            loading: () => const Center(child: CircularProgressIcon()),
            error: (exception, __) => ErrorWidget(exception),
            data: (notifications) {
              if (notifications == null) return const SizedBox.shrink();
              if (notifications.isEmpty) return const InfoView(title: Text('No Results'));

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final remoteNotification = notifications[index];
                  return ListTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(remoteNotification.repository!.name),
                        Text(remoteNotification.subject!.type!),
                      ],
                    ),
                    subtitle: Text(remoteNotification.subject!.title!),
                    trailing: IconButton(
                      onPressed: () => _markAsRead(remoteNotification.id!),
                      icon: const Icon(Icons.check),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 384.0,
      child: Column(
        children: [
          SwitchListTile(
            value: widget.repository.settings.hasBranchProtection,
            onChanged: _toggleBranchProtection,
            title: const Text('Enable branches protection?'),
            subtitle: const Text('master, develop, main'),
          ),
          const Divider(),
          Expanded(child: _buildNotifications()),
          const Divider(),
          Expanded(child: _buildCodeMagicBuilds()),
        ],
      ),
    );
  }
}
