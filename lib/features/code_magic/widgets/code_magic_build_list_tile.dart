import 'package:collection/collection.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:gitle/features/code_magic/code_magic_dto.dart';
import 'package:gitle/features/code_magic/code_magic_utils.dart';
import 'package:gitle/shared/flutter_extensions.dart';
import 'package:gitle/shared/info_box.dart';
import 'package:mek/mek.dart';

class CodeMagicBuildListTile extends StatelessWidget {
  final Build _build;
  final Widget? trailing;

  const CodeMagicBuildListTile({super.key, required Build build, required this.trailing})
    : _build = build;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => CodeMagicUtils.launchBuildUrl(_build),
      leading: CodeMagicUtils.buildStatusIcon(_build.status),
      title: Text(
        'Workflow: ${_build.fileWorkflowId ?? '-'} - ${CodeMagicUtils.translateOrigin(_build)}',
      ),
      subtitle: InfoBox(
        children: [
          if (_build.startedAt case final startedAt?)
            InfoBoxTile(
              label: const Text('Started at:'),
              child: Text(context.formatDateTime(startedAt)),
            ),
          if (_build.finishedAt case final finishedAt?)
            InfoBoxTile(
              label: const Text('Finished at:'),
              child: Text(context.formatDateTime(finishedAt)),
            ),
        ],
      ),
      trailing: trailing,
    );
  }
}

class CodeMagicBuildsView extends StatelessWidget {
  final IList<Application> applications;
  final IList<Build> builds;
  final void Function(Application applicaiton, Build build) onDelete;

  const CodeMagicBuildsView({
    super.key,
    required this.applications,
    required this.builds,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final groups = <(String, String?, List<Build>)>[];
    for (final build in builds) {
      final lastGroup = groups.lastOrNull;

      if (lastGroup != null) {
        final (appId, buildVersion, builds) = lastGroup;
        if (appId == build.appId && buildVersion == build.version) {
          builds.add(build);
          continue;
        }
      }

      groups.add((build.appId, build.version, [build]));
    }

    return ListView.separated(
      itemCount: groups.length,
      separatorBuilder: (context, index) => const Divider(indent: 16.0, endIndent: 16.0),
      itemBuilder: (context, index) {
        final (applicationId, buildVersion, builds) = groups[index];
        final application = applications.firstWhere((e) => e.id == applicationId);
        final pendingBuilds = builds.where((e) => e.status.isPending);

        return Column(
          children: [
            ParagraphTile(
              onTap: () => CodeMagicUtils.launchBuildsUrl(applicationId: applicationId),
              leading: Text(buildVersion ?? '-.-.-'),
              subtitle: Text(application.name),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () => CodeMagicUtils.launchApplicationUrl(applicationId),
                    child: const Text('Go to app settings'),
                  ),
                  if (pendingBuilds.isNotEmpty)
                    PopupMenuItem(
                      onTap: () {
                        for (final build in pendingBuilds) {
                          onDelete(application, build);
                        }
                      },
                      child: const Text('Cancel all builds'),
                    ),
                ],
              ),
            ),
            ...builds.map((build) {
              return CodeMagicBuildListTile(
                build: build,
                trailing: build.status.isPending
                    ? IconButton(
                        onPressed: () => onDelete(application, build),
                        icon: const Icon(Icons.delete),
                      )
                    : null,
              );
            }),
          ],
        );
      },
    );
  }
}
