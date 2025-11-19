import 'package:flutter/material.dart';
import 'package:gitle/common/app_utils.dart';
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

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(GitHubProviders.notifications);

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
          TextButton(onPressed: () => _markAllAsRead(none), child: Text('Mark All As Read')),
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
      ),
    );
  }
}
