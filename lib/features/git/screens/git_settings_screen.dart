import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gitle/features/git_hub/git_hub_providers.dart';
import 'package:mek/mek.dart';
import 'package:reactive_forms/reactive_forms.dart';

class GitSettingsScreen extends SourceConsumerStatefulWidget {
  const GitSettingsScreen({super.key});

  @override
  SourceConsumerState<GitSettingsScreen> createState() => _GitSettingsScreenState();
}

class _GitSettingsScreenState extends SourceConsumerState<GitSettingsScreen> {
  final _tokenFb = FormControlTyped(initialValue: '');
  final _shouldNotifyFb = FormControlTyped(initialValue: true);

  late final _form = FormArray([_tokenFb, _shouldNotifyFb]);

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
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDirty = ref.watchSource(_form.source.dirty);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ReactiveTypedTextField(
              formControl: _tokenFb,
              variant: const TextFieldVariant.secret(),
              decoration: const InputDecoration(labelText: 'GitHub Token'),
            ),
          ),
          ReactiveSwitchListTile(
            formControl: _shouldNotifyFb,
            title: const Text('GitHub Notifications'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isDirty
            ? () {
                unawaited(
                  GitHubProviders.update(
                    token: _tokenFb.value,
                    shouldNotify: _shouldNotifyFb.value,
                  ),
                );
                context.nav.pop();
              }
            : null,
        child: const Icon(Icons.save_outlined),
      ),
    );
  }
}
