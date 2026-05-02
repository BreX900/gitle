import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/features/git_hub/git_hub_providers.dart';
import 'package:gitle/shared/build_async_value_extensions.dart';
import 'package:mek/mek.dart';

class GitHubNotificationsDrawerView extends ConsumerStatefulWidget {
  const GitHubNotificationsDrawerView({super.key});

  @override
  ConsumerState<GitHubNotificationsDrawerView> createState() =>
      _GitHubNotificationsDrawerViewState();
}

class _GitHubNotificationsDrawerViewState extends ConsumerState<GitHubNotificationsDrawerView> {
  late final _mutation = MutationController(ref);

  @override
  void dispose() {
    _mutation.dispose();
    super.dispose();
  }

  void _markAsRead(String id) {
    _mutation(
      (ref) async => await GitHubProviders.markAsRead(ref, id),
      onError: (error, stackTrace) => AppUtils.showErrorSnackBar(context, error),
    );
  }

  void _markAllAsRead() {
    _mutation(
      (ref) async => await GitHubProviders.markAllAsRead(ref, none),
      onError: (error, stackTrace) => AppUtils.showErrorSnackBar(context, error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(GitHubProviders.notifications);
    final isIdle = !ref.watch(_mutation.provider.isPending);

    return Column(
      crossAxisAlignment: .end,
      children: [
        ParagraphTile(
          title: const Text('Notifications'),
          trailing: TextButton(
            onPressed: isIdle ? _markAllAsRead : null,
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
                      onPressed: isIdle ? () => _markAsRead(remoteNotification.id!) : null,
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
