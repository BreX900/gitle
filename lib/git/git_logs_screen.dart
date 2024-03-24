import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitle/git/clients/git_extensions.dart';
import 'package:mek/mek.dart';

class GitLogsScreen extends ConsumerWidget {
  const GitLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(GitDirExtensions.outputStream.provider);

    final child = Scaffold(
      appBar: AppBar(),
      body: ListView.builder(
        reverse: true,
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final log = logs[index];

          return ListTile(
            minVerticalPadding: 0,
            leading: Text('${log.exitCode}'),
            title: Text('${log.name} ${log.args.join(' ')}'),
            subtitle: Text(log.message),
          );
        },
      ),
    );
    return SelectionArea(child: child);
  }
}
