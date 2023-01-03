import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:sidekick/sidekick.dart';
import 'package:sidekick_core/sidekick_core.dart' hide version;

/// Updates the global sidekick CLI
///
/// A target version can be specified as positional argument. If no version is
/// given, updates to the latest available version.
class UpdateCommand extends Command {
  UpdateCommand({required this.processManager});

  @override
  final String description = 'Updates the global sidekick CLI';

  @override
  final String name = 'update';

  @override
  String get invocation => super.invocation.replaceFirst(
        '[arguments]',
        "[{<version>, 'latest'}]",
      );

  final ProcessManager processManager;

  @override
  Future<void> run() async {
    final targetVersion = await _versionFromArgs(argResults!);

    final isUpToDate = version == targetVersion;
    if (isUpToDate) {
      print('No need to update because the global sidekick CLI already is '
          'at the specified or latest version ($targetVersion).');
      return;
    }

    try {
      final process = processManager.runSync(
        [
          'dart',
          'pub',
          'global',
          'activate',
          'sidekick',
          targetVersion.toString(),
        ],
      );
      if (process.exitCode != 0) {
        throw 'Updating sidekick failed, this is the stderr output of '
            '`dart pub global activate`:\n${process.stderr}';
      }
    } catch (_) {
      print(
        red('Update to $targetVersion failed. Please check your internet '
            'connection and whether the sidekick version exists on pub.dev.'),
      );
      rethrow;
    }
    print(
      green('Successfully updated sidekick from $version to $targetVersion!'),
    );
  }

  FutureOr<Version> _versionFromArgs(ArgResults args) {
    final rest = args.rest;
    if (rest.isEmpty || rest.first == 'latest') {
      return _getLatestDependencyVersion('sidekick');
    }
    try {
      return Version.parse(rest.first);
    } on FormatException catch (_) {
      throw "'${rest.first}' is not a valid semver version.";
    }
  }
}

/// Returns the latest version of [dependency] available on pub.dev
Future<Version> _getLatestDependencyVersion(String dependency) async {
  if (testFakeGetLatestDependencyVersion != null) {
    return testFakeGetLatestDependencyVersion!(dependency);
  }

  final response =
      await get(Uri.parse('https://pub.dev/api/packages/$dependency'));

  if (response.statusCode != HttpStatus.ok) {
    throw "Package '$dependency' not found on pub.dev";
  }

  final latestVersion =
      ((jsonDecode(response.body) as Map<String, dynamic>)['latest']
          as Map<String, dynamic>)['version'] as String;

  return Version.parse(latestVersion);
}

@visibleForTesting
Future<Version> Function(String dependency)? testFakeGetLatestDependencyVersion;
