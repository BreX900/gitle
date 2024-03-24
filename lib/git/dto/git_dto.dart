import 'package:collection/collection.dart';
import 'package:git/git.dart';
import 'package:gitle/git/clients/git_extensions.dart';
import 'package:mek_data_class/mek_data_class.dart';

part 'git_dto.g.dart';

@DataClass(stringify: false)
class CommandLogDto with _$CommandLogDto {
  final String name;
  final List<String> args;
  final int exitCode;
  final String message;

  const CommandLogDto({
    required this.name,
    required this.args,
    required this.exitCode,
    required this.message,
  });

  @override
  String toString() =>
      '$name ${args.join(' ')}\n${message.split('\n').map((e) => '  $e').join('\n')}';
}

@DataClass(stringify: false)
class LogActionDto with _$LogActionDto {
  final String username;
  final String email;
  final DateTime date;

  const LogActionDto({
    required this.username,
    required this.email,
    required this.date,
  });

  static final _regExp = RegExp('(.*) <(.*)> (.*) (.*)');

  factory LogActionDto.parse(String source) {
    final match = _regExp.matchAsPrefix(source)!;
    return LogActionDto(
      username: match[1]!,
      email: match[2]!,
      date: DateTime.fromMillisecondsSinceEpoch(int.parse(match[3]!) * 1000),
    );
  }

  @override
  String toString() => '$username <$email> $date';
}

@DataClass(stringify: false)
class LogDto with _$LogDto {
  final Sha commit;
  final Sha? parent;
  final LogActionDto author;
  final LogActionDto committer;
  final List<String> message;

  const LogDto({
    required this.commit,
    required this.parent,
    required this.author,
    required this.committer,
    required this.message,
  });

  @override
  String toString() =>
      'commit $commit\n${parent == null ? '' : 'parent $parent\n'}author $author\ncommitter $committer\n\n$message\n';
}

enum FileStatus {
  modified('M'),
  typeChanged('T'),
  added('A'),
  deleted('D'),
  renamed('R'),
  copied('C'),
  updatedAndUnmerged('U'), // Rebasing...
  untracked('?');

  final String shortName;

  const FileStatus(this.shortName);

  static FileStatus? parse(String source) {
    if (source == ' ') return null;
    return FileStatus.values.firstWhere((e) => e.shortName == source);
  }
}

typedef Sha = String;

@DataClass()
class Stash with _$Stash {
  final String name;
  final LogActionDto author;
  final LogActionDto committer;
  final List<String> message;

  const Stash({
    required this.name,
    required this.author,
    required this.committer,
    required this.message,
  });
}

@DataClass()
class FileDto with _$FileDto {
  final List<FileStatus> status;
  final List<String> paths;

  const FileDto({
    required this.status,
    required this.paths,
  });

  @override
  String toString() => '${status.map((e) => e.shortName).join().padLeft(2)} ${paths.join(' -> ')}';
}

@DataClass()
class BranchReferenceWithUpstream with _$BranchReferenceWithUpstream {
  final bool isHead;
  final String name;
  final Sha commit;
  final String? upstream;
  final List<String> message;

  const BranchReferenceWithUpstream({
    required this.isHead,
    required this.name,
    required this.commit,
    required this.upstream,
    required this.message,
  });
}

@DataClass()
class Mark with _$Mark {
  final bool hasHead;
  final CommitReference? remote;
  final CommitReference? local;

  Mark({
    required this.hasHead,
    required this.remote,
    required this.local,
  }) : assert(remote != null || local != null);

  String get sha => (local ?? remote)!.sha;

  bool get isAligned {
    final remote = this.remote;
    final local = this.local;
    if (local == null || remote == null) return false;
    return local.sha == remote.sha;
  }

  static String parseName(String reference) => reference.replaceFirst(RegExp('refs/[^/]+/'), '');

  static bool matchIsTag(String reference) => reference.startsWith('refs/tags/');
  static bool matchIsLocal(String reference) => reference.startsWith('refs/heads/');
  static bool matchIsRemote(String reference) => reference.startsWith('refs/remotes/');

  static List<Mark> from({
    required Iterable<CommitReference> references,
    required Iterable<BranchReferenceWithUpstream> branches,
  }) {
    final remotes = references.where((element) => element.isRemote).toList();
    final locals = references.where((element) => element.isLocal);

    final pickedRemotes = <CommitReference>[];

    final marks = <Mark>[];

    for (final local in locals) {
      var hasHead = false;
      CommitReference? remote;

      if (local.isLocal) {
        final branchWithUpstream = branches.firstWhereOrNull((e) => e.name == local.name);
        hasHead = branchWithUpstream?.isHead ?? false;

        final upstream = branchWithUpstream?.upstream;
        if (upstream != null) {
          final candidateRemote = remotes.firstWhereOrNull((e) => e.name == upstream);

          if (candidateRemote != null && local.sha == candidateRemote.sha) {
            remote = candidateRemote;
            pickedRemotes.add(candidateRemote);
          }
        }
      }

      marks.add(Mark(
        hasHead: hasHead,
        local: local,
        remote: remote,
      ));
    }

    for (final remote in remotes) {
      if (pickedRemotes.contains(remote)) continue;
      marks.add(Mark(
        hasHead: false,
        remote: remote,
        local: null,
      ));
    }

    for (final tag in references.where((element) => element.isTag)) {
      marks.add(Mark(
        hasHead: false,
        remote: tag,
        local: null,
      ));
    }

    return marks;
  }
}
