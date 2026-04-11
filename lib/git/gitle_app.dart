import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gitle/features/code_magic/code_magic_providers.dart';
import 'package:gitle/features/git_hub/git_hub_providers.dart';
import 'package:gitle/features/repositories/repositories_providers.dart';
import 'package:gitle/git/git_screen.dart';
import 'package:mek/mek.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:window_manager/window_manager.dart';

class GitleApp extends SourceConsumerStatefulWidget {
  const GitleApp({super.key});

  @override
  SourceConsumerState<GitleApp> createState() => _MyAppState();
}

class _MyAppState extends SourceConsumerState<GitleApp> with WindowListener {
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    // WindowManager.instance.addListener(this);

    ref.listenManual(fireImmediately: true, RepositoriesProviders.current, (prev, next) async {
      final prevPath = prev?.value?.gitDir.path;
      final nextPath = next.value?.gitDir.path;
      if (prevPath == nextPath) return;

      final rebaseFile = File('$nextPath/.git/REBASE_HEAD');
      await _subscription?.cancel();
      _subscription = rebaseFile
          .watch(events: FileSystemEvent.create | FileSystemEvent.delete)
          .listen((_) {
            ref.invalidate(RepositoriesProviders.current);
          });
    });

    /// Start listening GitHub notifications
    ref.listenManual(GitHubProviders.notificationsListener, (_, _) {});

    /// Start listening CodeMagic build notifications
    ref.listenManual(CodeMagicProviders.builds, (_, _) {});
  }

  @override
  void dispose() {
    // WindowManager.instance.removeListener(this);
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  // @override
  // void onWindowFocus() {
  //   super.onWindowFocus();
  //   ref.invalidate(RepositoriesProviders.current);
  // }

  @override
  Widget build(BuildContext context) {
    final theme = MekTheme.build(context: context);

    return MaterialApp(
      title: 'Gitle',
      debugShowCheckedModeBanner: false,
      theme: theme.copyWith(scaffoldBackgroundColor: theme.colorScheme.surface),
      locale: const Locale('it', 'IT'),
      supportedLocales: kWidgetsSupportedLanguages.map(Locale.new),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      builder: (context, child) {
        final colors = Theme.of(context).colorScheme;
        return MultiSplitViewTheme(
          data: MultiSplitViewThemeData(
            dividerPainter: DividerPainter(
              backgroundColor: Colors.grey[800],
              highlightedBackgroundColor: colors.surfaceTint,
            ),
          ),
          child: child!,
        );
      },
      home: const GitScreen(),
    );
  }
}
