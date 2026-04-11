import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/features/code_magic/code_magic_dto.dart';
import 'package:gitle/features/code_magic/code_magic_entities.dart';
import 'package:gitle/features/code_magic/code_magic_providers.dart';
import 'package:gitle/features/code_magic/code_magic_workflow_dialog.dart';
import 'package:gitle/shared/build_async_value_extensions.dart';
import 'package:mek/mek.dart';

final _provider = FutureProvider.autoDispose((ref) {
  final appsState = ref.watch(CodeMagicProviders.apps);
  final buildsState = ref.watch(CodeMagicProviders.builds);

  return (appsState.requireValue, buildsState.requireValue);
});

class CodeMagicBuildsDrawerView extends SourceConsumerStatefulWidget {
  final CodeMagicConfigEntity config;

  const CodeMagicBuildsDrawerView({super.key, required this.config});

  @override
  SourceConsumerState<CodeMagicBuildsDrawerView> createState() => _CodeMagicBuildsDrawerViewState();
}

class _CodeMagicBuildsDrawerViewState extends SourceConsumerState<CodeMagicBuildsDrawerView> {
  late final _createJobMutation = ref.mutationV2(CodeMagicProviders.createJob);
  late final _deleteJobMutation = ref.mutationV2(CodeMagicProviders.deleteJob);

  Future<void> _createJob(WidgetRef ref) async {
    final result = await showDialog<CodeMagicJobEntity>(
      context: ref.context,
      builder: (context) => const CodeMagicWorkflowDialog(),
    );
    if (result == null) return;

    _createJobMutation(result, onError: (error) => AppUtils.showErrorSnackBar(context, error));
  }

  Future<void> _deleteJob(WidgetRef ref, Application application, CodeMagicJobEntity job) async {
    final canDelete = await showDialog<bool>(
      context: ref.context,
      builder: (context) => AlertDialog(
        title: const Text('Delete job?'),
        content: Text(
          'Application: ${application.name}\n'
          'Workflow ids: ${job.workflowIds.join(',')}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (!(canDelete ?? false)) return;

    _deleteJobMutation(job, onError: (error) => AppUtils.showErrorSnackBar(context, error));
  }

  Widget _buildContent(
    WidgetRef ref, {
    required IList<Application> apps,
    required BuildsResponse buildsResponse,
  }) {
    return Column(
      crossAxisAlignment: .stretch,
      spacing: 12.0,
      children: [
        ParagraphTile(
          title: const Text('Jobs'),
          trailing: TextButton(onPressed: () => _createJob(ref), child: const Text('Create')),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Wrap(
            children: widget.config.jobs.map((job) {
              final applicaiton = apps.firstWhere((e) => e.id == job.appId);
              final hasPendingBuilds = buildsResponse.builds.any((e) {
                return e.appId == job.appId &&
                    job.workflowIds.contains(e.workflowId) &&
                    e.status.isPending;
              });

              return Chip(
                onDeleted: !hasPendingBuilds ? () => _deleteJob(ref, applicaiton, job) : null,
                label: Text(
                  textAlign: .center,
                  '${applicaiton.name} > ${job.workflowIds.join(',')}',
                ),
              );
            }).toList(),
          ),
        ),

        const Divider(),

        const ParagraphTile(title: Text('Builds')),
        Expanded(
          child: ListView.builder(
            itemCount: buildsResponse.builds.length,
            itemBuilder: (context, index) {
              final build = buildsResponse.builds[index];
              final app = buildsResponse.applications.firstWhere((e) => e.id == build.appId);

              return ListTile(
                leading: Tooltip(
                  message: build.status.name,
                  child: switch (build.status) {
                    BuildStatus.queued => const Icon(Icons.pending),
                    BuildStatus.preparing => const Icon(Icons.build, color: Colors.yellow),
                    BuildStatus.skipped => const Icon(Icons.skip_next, color: Colors.grey),
                    BuildStatus.fetching => const Icon(Icons.download, color: Colors.yellow),
                    BuildStatus.building => const CircularProgressIndicator(
                      constraints: .tightFor(width: 20.0, height: 20.0),
                      strokeWidth: 1.5,
                    ),
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
                title: Text('${app.name} - Version: ${build.version}'),
                subtitle: Text(
                  'From: ${build.tag ?? build.branch ?? '?'} - WorkflowId: ${build.workflowId ?? '-'}',
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(_provider);

    return Column(
      crossAxisAlignment: .stretch,
      children: [
        Expanded(
          child: state.buildView(
            data: (data) => _buildContent(ref, apps: data.$1, buildsResponse: data.$2),
          ),
        ),
      ],
    );
  }
}
