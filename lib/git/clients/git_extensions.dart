import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:git/git.dart';
import 'package:gitle/common/logger.dart';
import 'package:gitle/git/dto/git_dto.dart';
import 'package:mekart/mekart.dart';
import 'package:rxdart/rxdart.dart';

enum PushForce { enabled, enabledWithLease }

// git -c core.editor=true rebase --continue
extension GitDirExtensions on GitDir {
  static final RegExp _spaceOrTabRegExp = RegExp(r'[ \t]');
  static final RegExp _initialSpaceRegExp = RegExp('    ');
  static final RegExp _branchUpstreamRecordRegExp =
      RegExp(r'^(?<H>[ *]) (?<R>[^ ]+) +(?<C>[^ ]+)( \[(?<U>[^\]]+)])? (?<M>.+)$');

  static final _outputController = BehaviorSubject.seeded(<CommandLogDto>[]);
  static ValueStream<List<CommandLogDto>> get outputStream => _outputController.stream;

  Future<List<CommitReference>> lsRemotes({bool heads = false, bool tags = false}) async {
    final result = await runEffect(['ls-remote', if (heads) '--heads', if (tags) '--tags']);

    return CommitReference.fromShowRefOutput(result
        .split('\n')
        .map((e) => e.split(_spaceOrTabRegExp).where((e) => e.isNotEmpty).join(' '))
        .where((element) => element.isNotEmpty)
        .join('\n'));
  }

  Future<void> checkout(Sha commitOrBranch, {String? newBranchName}) async {
    await runEffect([
      'checkout',
      if (newBranchName != null) ...['-b', newBranchName],
      commitOrBranch
    ]);
  }

  Future<void> reset({int count = 1, bool isSoft = true}) async {
    await runEffect(['reset', 'HEAD~$count', if (isSoft) '--soft']);
  }

  Future<void> add() async {
    await runEffect(['add', '-A']);
  }

  Future<void> stashPush({String? message, List<String> filePaths = const []}) async {
    await runEffect([
      'stash',
      'push',
      if (message != null) ...['--message', message],
      ...filePaths,
    ]);
  }

  Future<void> stashApply(String id) async {
    await runEffect(['stash', 'apply', id]);
  }

  Future<List<Stash>> stashList() async {
    final result = await runEffect(['stash', 'list', '--format=raw']);

    final reader = StringScanner(result);

    final stashes = <Stash>[];

    while (reader.moveNext()) {
      if (reader.current.isEmpty) continue;

      final dataLines = <String>[];

      do {
        dataLines.add(reader.current);
      } while (reader.moveNext() && reader.current.isNotEmpty);

      String getDataLine(String name) {
        return dataLines
            .firstWhere((element) => element.startsWith(name), orElse: () => '')
            .replaceFirst('$name ', '');
      }

      final lines = <String>[];
      while (reader.moveNext() && reader.current.startsWith(_initialSpaceRegExp)) {
        lines.add(reader.current.substring(4));
      }

      stashes.add(Stash(
        // commit: _parseSha(getDataLine('commit')),
        // parent: getDataLine('parent').isEmpty ? null : _parseSha(getDataLine('parent')),
        author: LogActionDto.parse(getDataLine('author')),
        committer: LogActionDto.parse(getDataLine('committer')),
        name: getDataLine('Reflog:').split(' ')[0],
        message: lines,
      ));
    }
    return stashes;
  }

  Future<void> stashDrop(String id) async {
    await runEffect(['stash', 'drop', id]);
  }

  /// https://git-scm.com/docs/git-branch
  /// [startPoint] is a CommitSha
  Future<void> branch(String name, {Sha? startPoint}) async {
    await runEffect(['branch', name, if (startPoint != null) startPoint]);
  }

  Future<void> branchDelete(String name, {bool force = false}) async {
    await runEffect(['branch', '--delete', if (force) '--force', name]);
  }

  Future<void> branchRename(String name, String newName) async {
    await runEffect(['branch', '--move', name, newName]);
  }

  Future<List<BranchReferenceWithUpstream>> branchUpstreams() async {
    final result = await runCommand(['branch', '-vv', '--no-abbrev']);

    final text = result.stdout as String;
    final reader = StringScanner(text);

    final branches = <BranchReferenceWithUpstream>[];

    while (reader.moveNext()) {
      if (reader.current.isEmpty) continue;

      final line = reader.current;

      final match = _branchUpstreamRecordRegExp.firstMatch(line)!;

      branches.add(BranchReferenceWithUpstream(
        isHead: match.namedGroup('H')! == '*',
        name: match.namedGroup('R')!,
        commit: match.namedGroup('C')!,
        upstream: match.namedGroup('U')?.split(':').firstOrNull,
        message: match.namedGroup('M')?.split('\n') ?? [],
      ));
    }

    return branches;
  }

  /// https://git-scm.com/docs/git-commit
  Future<void> commit({
    bool amend = false,
    String message = '',
    List<String> filePaths = const [],
  }) async {
    final fixedMessage = message.trim();
    await runEffect([
      'commit',
      if (amend) '--amend',
      if (fixedMessage.isNotEmpty) '--message=$fixedMessage',
      ...filePaths,
    ]);
  }

  /// https://git-scm.com/docs/git-fetch
  Future<void> fetch({String? remoteBranchName, String? localBranch, bool prune = false}) async {
    await runEffect([
      'fetch',
      if (remoteBranchName != null && localBranch != null) ...[
        'origin',
        '$remoteBranchName:$localBranch'
      ] else
        '--all',
      if (prune) '--prune',
    ]);
  }

  /// https://git-scm.com/docs/git-push
  Future<void> push({
    bool setUpstream = false,
    PushForce? force,
    String? referenceName,
    bool toOrigin = false,
  }) async {
    await runEffect([
      'push',
      if (setUpstream) ...['--set-upstream', 'origin'],
      if (force == PushForce.enabled) '--force',
      if (force == PushForce.enabledWithLease) '--force-with-lease',
      if (toOrigin) 'origin',
      if (referenceName != null) referenceName,
    ]);
  }

  Future<void> pushDelete(String branchOrTagName) async {
    await runEffect(['push', 'origin', '--delete', branchOrTagName]);
  }

  /// https://git-scm.com/docs/git-pull
  Future<void> pull(String remoteBranchName) async {
    await runEffect(['pull', 'origin', remoteBranchName]);
  }

  Future<String?> rebase(String name, {bool continue$ = false}) async {
    final message = await runEffect(['rebase', name, if (continue$) '--continue']);
    return message.isEmpty ? null : message;
  }

  Future<String> rebaseContinue({bool editor = false}) async {
    return await runEffect([
      if (editor) ...['-c', 'core.editor=true'],
      'rebase',
      '--continue'
    ]);
  }

  Future<String> rebaseAbort() async {
    return await runEffect(['rebase', '--abort']);
  }

  /// https://git-scm.com/book/en/v2/Git-Basics-Tagging
  /// https://git-scm.com/docs/git-tag
  Future<void> createAnnotatedTag(String name, {Sha? commit, String? message}) async {
    message = message?.trim();
    await runEffect([
      'tag',
      '--annotate',
      name,
      if (message != null) ...['--message', message],
      if (commit != null) commit,
    ]);
  }

  /// https://git-scm.com/docs/git-status
  Future<List<FileDto>> status() async {
    final result = await runCommand(['status', '--untracked-files=all', '--porcelain']);
    final text = result.stdout as String;
    final reader = StringScanner(text);

    final files = <FileDto>[];

    while (reader.moveNext()) {
      final line = reader.current;
      if (line.isEmpty) continue;

      final status1 = FileStatus.parse(line.substring(0, 1));
      final status2 = FileStatus.parse(line.substring(1, 2));
      final filePaths = line.substring(3).split(' -> ');
      final firstFilePath = filePaths.elementAt(0);
      final lastFilePath = filePaths.elementAtOrNull(1);

      files.add(FileDto(
        status: [if (status1 != null) status1, if (status2 != null) status2],
        paths: [firstFilePath, if (lastFilePath != null) lastFilePath],
      ));
    }
    return files;
  }

  // Future<List<CommitReference>> showRefV2({
  //   bool head = false,
  //   bool heads = false,
  //   bool tags = false,
  // }) async {
  //   final args = ['show-ref', if (head) '--head', if (heads) '--heads', if (tags) '--tags'];
  //
  //   final pr = await runCommand(args, throwOnError: false);
  //   if (pr.exitCode == 1) {
  //     // no heads present, return empty collection
  //     return [];
  //   }
  //   // otherwise, it should have worked fine...
  //   assert(pr.exitCode == 0);
  //   return CommitReference.fromShowRefOutput(pr.stdout as String);
  // }

  Future<List<LogDto>> logs({
    bool tags = false,
    Iterable<String> paths = const [],
    int? maxCount,
  }) async {
    final result = await runCommand([
      'log',
      '--format=raw',
      '--date-order',
      if (tags) '--tags',
      if (maxCount != null) '--max-count=$maxCount',
      if (paths.isEmpty) '--all' else ...paths,
      // '--reverse',
      // if (branches.isNotEmpty) '--branches=${branches.join(',')}',
      // '--show-pulls',
    ]);

    final text = result.stdout as String;
    final reader = StringScanner(text);

    final logs = <LogDto>[];

    while (reader.moveNext()) {
      if (reader.current.isEmpty) continue;

      final data = <String, String>{};

      do {
        final line = reader.current;
        final spaceIndex = line.indexOf(' ');
        data[line.substring(0, spaceIndex)] = line.substring(spaceIndex + 1, line.length);
      } while (reader.moveNext() && reader.current.isNotEmpty);

      final lines = <String>[];
      while (reader.moveNext() && reader.current.startsWith(_initialSpaceRegExp)) {
        final line = reader.current;
        lines.add(line.substring(4));
      }

      logs.add(LogDto(
        commit: data.require('commit'),
        parent: data['parent'],
        author: LogActionDto.parse(data.require('author')),
        committer: LogActionDto.parse(data.require('committer')),
        message: lines,
      ));
    }

    return logs;
  }

  Future<String> runEffect(List<String> args) async {
    final result = await runCommand(args, throwOnError: false);

    final commandResult = CommandLogDto(
      name: 'git',
      args: args,
      exitCode: result.exitCode,
      message: result.exitCode != 0 ? result.stderr : result.stdout,
    );
    lg.fine(commandResult);
    _outputController.add([commandResult, ..._outputController.value]);
    if (result.exitCode != 0) _throwFailedProcess(result, 'git', args);

    return result.stdout;
  }
}

void _throwFailedProcess(ProcessResult pr, String process, List<String> args) {
  final values = {
    if (pr.stdout != null) 'Standard out': pr.stdout.toString().trim(),
    if (pr.stderr != null) 'Standard error': pr.stderr.toString().trim()
  }..removeWhere((k, v) => v.isEmpty);

  String message;
  if (values.isEmpty) {
    message = 'Unknown error';
  } else if (values.length == 1) {
    message = values.values.single;
  } else {
    message = values.entries.map((e) => '${e.key}\n${e.value}').join('\n');
  }

  throw ProcessException(process, args, message, pr.exitCode);
}

extension NameCommitReference on CommitReference {
  String get name => Mark.parseName(reference);
  String toBranchName() => name.replaceFirst('origin/', '');
  // String toRemoteName() => name.startsWith('origin/') ? name : 'origin/$name';
  bool get isTag => Mark.matchIsTag(reference);
  bool get isLocal => Mark.matchIsLocal(reference);
  bool get isRemote => Mark.matchIsRemote(reference);
}

class StringScanner extends Iterable<String> implements Iterator<String> {
  final String source;

  int? _currentLineIndex = 0;
  String? _currentLine;

  StringScanner(this.source);

  @override
  Iterator<String> get iterator => this;

  @override
  bool moveNext() {
    _currentLine = _readNextLine();
    return _currentLine != null;
  }

  @override
  String get current => _currentLine!;

  String? _readNextLine() {
    final prevLineIndex = _currentLineIndex;
    if (prevLineIndex == null) return null;

    final nextLF = source.indexOf('\n', prevLineIndex);

    if (nextLF < 0) {
      _currentLineIndex = null;
      // no more new lines, return what's left and set postion = null
      return source.substring(prevLineIndex, source.length);
    }

    _currentLineIndex = nextLF + 1;

    // to handle Windows newlines, see if the value before nextLF is a Carriage
    final isWinNL = nextLF > 0 && source.substring(nextLF - 1, nextLF) == '\r';

    return isWinNL
        ? source.substring(prevLineIndex, nextLF - 1)
        : source.substring(prevLineIndex, nextLF);
  }
}
