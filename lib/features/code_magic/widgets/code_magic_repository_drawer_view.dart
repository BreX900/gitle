import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/features/code_magic/code_magic_dto.dart';
import 'package:gitle/features/code_magic/code_magic_entities.dart';
import 'package:gitle/features/code_magic/code_magic_providers.dart';
import 'package:gitle/features/code_magic/code_magic_utils.dart';
import 'package:gitle/features/code_magic/widgets/code_magic_build_list_tile.dart';
import 'package:gitle/features/code_magic/widgets/code_magic_workflow_dialog.dart';
import 'package:gitle/shared/answer_dialog.dart';
import 'package:gitle/shared/build_async_value_extensions.dart';
import 'package:mek/mek.dart';

final _provider = FutureProvider.autoDispose((ref) {
  final appsState = ref.watch(CodeMagicProviders.apps);
  final buildsState = ref.watch(CodeMagicProviders.builds);

  return (appsState.requireValue, buildsState.requireValue);
});

class CodeMagicRepositoryDrawerView extends ConsumerStatefulWidget {
  final CodeMagicConfigEntity config;

  const CodeMagicRepositoryDrawerView({super.key, required this.config});

  @override
  ConsumerState<CodeMagicRepositoryDrawerView> createState() =>
      _CodeMagicRepositoryDrawerViewState();
}

class _CodeMagicRepositoryDrawerViewState extends ConsumerState<CodeMagicRepositoryDrawerView> {
  late final _mutation = MutationController(ref);

  @override
  void dispose() {
    _mutation.dispose();
    super.dispose();
  }

  Future<void> _createJob() async {
    final result = await showDialog<CodeMagicJobEntity>(
      context: context,
      builder: (context) => const CodeMagicWorkflowDialog(),
    );
    if (result == null) return;

    _mutation(
      (ref) => CodeMagicProviders.createJob(ref, result),
      onError: (error, stackTrace) => AppUtils.showErrorSnackBar(context, error),
    );
  }

  Future<void> _deleteJob(Application application, CodeMagicJobEntity job) async {
    final canDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AnswerDialog.delete(
        content: Text(
          'Application: ${application.name}\n'
          'Workflow ids: ${job.workflowIds.join(',')}',
        ),
      ),
    );
    if (!(canDelete ?? false)) return;

    _mutation(
      (ref) => CodeMagicProviders.deleteJob(ref, job),
      onError: (error, stackTrace) => AppUtils.showErrorSnackBar(context, error),
    );
  }

  Future<void> _cancelBuild(Application application, Build build) async {
    final canDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AnswerDialog.delete(
        content: Text(
          'Application: ${application.name}\n'
          '${build.tag ?? build.branch ?? '?'} - Workflow: ${build.fileWorkflowId ?? '?'}',
        ),
      ),
    );
    if (!(canDelete ?? false)) return;

    _mutation(
      (ref) => CodeMagicProviders.cancelBuild(ref, build.id),
      onError: (error, stackTrace) => AppUtils.showErrorSnackBar(context, error),
    );
  }

  Widget _buildContent(
    WidgetRef ref, {
    required IList<Application> apps,
    required BuildsResponse buildsResponse,
  }) {
    final builds = buildsResponse.builds.where((build) {
      return widget.config.jobs.any((job) {
        return job.appId == build.appId && job.workflowIds.contains(build.fileWorkflowId);
      });
    }).toIList();

    return Column(
      crossAxisAlignment: .stretch,
      spacing: 12.0,
      children: [
        ParagraphTile(
          title: const Text('Jobs'),
          trailing: TextButton(onPressed: _createJob, child: const Text('Create')),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Wrap(
            spacing: 4.0,
            runSpacing: 4.0,
            children: widget.config.jobs.map((job) {
              final application = apps.firstWhere((e) => e.id == job.appId);
              final hasPendingBuilds = builds.any((e) {
                return job.appId == e.appId &&
                    job.workflowIds.contains(e.fileWorkflowId) &&
                    e.status.isPending;
              });

              return Chip(
                onDeleted: !hasPendingBuilds ? () => _deleteJob(application, job) : null,
                label: Text(
                  textAlign: .center,
                  '${application.name} > ${job.workflowIds.join(',')}',
                ),
              );
            }).toList(),
          ),
        ),

        const Divider(),

        const ParagraphTile(onTap: CodeMagicUtils.launchBuildsUrl, title: Text('Builds')),
        Expanded(
          child: CodeMagicBuildsView(
            applications: buildsResponse.applications,
            builds: buildsResponse.builds,
            onDelete: _cancelBuild,
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
