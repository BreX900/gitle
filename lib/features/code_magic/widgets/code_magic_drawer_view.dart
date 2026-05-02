import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitle/common/app_utils.dart';
import 'package:gitle/features/code_magic/code_magic_dto.dart';
import 'package:gitle/features/code_magic/code_magic_entities.dart';
import 'package:gitle/features/code_magic/code_magic_providers.dart';
import 'package:gitle/features/code_magic/code_magic_utils.dart';
import 'package:gitle/features/code_magic/widgets/code_magic_build_list_tile.dart';
import 'package:gitle/shared/answer_dialog.dart';
import 'package:gitle/shared/build_async_value_extensions.dart';
import 'package:mek/mek.dart';

final _provider = FutureProvider.autoDispose((ref) {
  final buildsState = ref.watch(CodeMagicProviders.builds);

  return buildsState.requireValue;
});

class CodeMagicDrawerView extends ConsumerStatefulWidget {
  final CodeMagicConfigEntity config;

  const CodeMagicDrawerView({super.key, required this.config});

  @override
  ConsumerState<CodeMagicDrawerView> createState() => _CodeMagicDrawerViewState();
}

class _CodeMagicDrawerViewState extends ConsumerState<CodeMagicDrawerView> {
  late final _mutation = MutationController(ref);

  @override
  void dispose() {
    _mutation.dispose();
    super.dispose();
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

  Widget _buildContent({required BuildsResponse buildsResponse}) {
    return Column(
      crossAxisAlignment: .stretch,
      spacing: 12.0,
      children: [
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

    return state.buildView(data: (data) => _buildContent(buildsResponse: data));
  }
}
