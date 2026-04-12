import 'package:flutter/material.dart';
import 'package:gitle/features/code_magic/code_magic_dto.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class CodeMagicUtils {
  static String translateOrigin(Build build) {
    if (build.tag case final tag?) {
      return 'Tag: $tag';
    } else if (build.branch case final branch?) {
      return 'Branch: $branch';
    }
    return 'Commit: ${build.commit.hash.substring(0, 8)}';
  }

  static Widget buildStatusIcon(BuildStatus status) {
    return Tooltip(
      message: status.name,
      child: switch (status) {
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
        BuildStatus.finishing => const Icon(Icons.cleaning_services, color: Colors.yellow),
        BuildStatus.finished => const Icon(Icons.check_circle, color: Colors.green),
      },
    );
  }

  static Future<void> launchApplicationUrl(String applicationId) async {
    await launchUrl(Uri.https('codemagic.io', '/app/$applicationId/settings'));
  }

  static Future<void> launchBuildsUrl({String? applicationId}) async {
    final url = Uri.https('codemagic.io', '/builds', <String, String>{
      if (applicationId != null) 'app_id': applicationId,
    });
    await launchUrl(url);
  }

  static Future<void> launchBuildUrl(Build build) async {
    await launchUrl(Uri.https('codemagic.io', '/app/${build.appId}/build/${build.id}'));
  }
}
