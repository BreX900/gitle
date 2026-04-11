import 'package:flutter/material.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/features/git_hub/git_hub_providers.dart';
import 'package:gitle/shared/build_async_value_extensions.dart';
import 'package:mek/mek.dart';

class GitHubNotificationsDrawerView extends SourceConsumerStatefulWidget {
  const GitHubNotificationsDrawerView({super.key});

  @override
  SourceConsumerState<GitHubNotificationsDrawerView> createState() =>
      _GitHubNotificationsDrawerViewState();
}

class _GitHubNotificationsDrawerViewState
    extends SourceConsumerState<GitHubNotificationsDrawerView> {
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

    return Column(
      crossAxisAlignment: .end,
      children: [
        ParagraphTile(
          title: const Text('Notifications'),
          trailing: TextButton(
            onPressed: () => _markAllAsRead(none),
            child: const Text('Mark All As Read'),
          ),
        ),
        Expanded(
          child: notifications.buildView(
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
}
