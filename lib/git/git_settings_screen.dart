import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gitle/git/providers/git_hub_providers.dart';
import 'package:mek/mek.dart';

class GitSettingsScreen extends ConsumerStatefulWidget {
  const GitSettingsScreen({super.key});

  @override
  ConsumerState<GitSettingsScreen> createState() => _GitSettingsScreenState();
}

class _GitSettingsScreenState extends ConsumerState<GitSettingsScreen> {
  final _tokenFb = FieldBloc(initialValue: '');
  final _shouldNotifyFb = FieldBloc(initialValue: true);

  late final _form = ListFieldBloc(fieldBlocs: [_tokenFb, _shouldNotifyFb]);

  @override
  void initState() {
    super.initState();
    ref.listenManual(GitHubProviders.token, (prev, next) {
      _tokenFb.updateValue(next);
    }, fireImmediately: true);
    ref.listenManual(GitHubProviders.shouldNotify, (prev, next) {
      _shouldNotifyFb.updateValue(next);
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    unawaited(_form.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDirty = ref.watch(_form.select((state) => state.isDirty));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FieldText(
              fieldBloc: _tokenFb,
              converter: FieldConvert.text,
              type: const TextFieldType.secret(),
              decoration: const InputDecoration(labelText: 'GitHub Token'),
            ),
          ),
          FieldSwitchListTile(
            fieldBloc: _shouldNotifyFb,
            title: const Text('GitHub Notifications'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isDirty
            ? () {
                unawaited(GitHubProviders.update(
                  token: _tokenFb.state.value,
                  shouldNotify: _shouldNotifyFb.state.value,
                ));
                context.nav.pop();
              }
            : null,
        child: const Icon(Icons.save_outlined),
      ),
    );
  }
}
