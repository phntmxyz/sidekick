import 'dart:async';

import 'package:process/process.dart';
import 'package:sidekick/sidekick.dart';
import 'package:sidekick_core/sidekick_core.dart' hide version;

/// Updates the global sidekick CLI
///
/// A target version can be specified as positional argument. If no version is
/// given, updates to the latest available version.
class UpdateCommand extends Command {
  UpdateCommand({
    required this.versionChecker,
    required this.processManager,
  });

  @override
  final String description = 'Updates the global sidekick CLI';

  @override
  final String name = 'update';

  @override
  String get invocation => super.invocation.replaceFirst(
        '[arguments]',
        "[{<version>, 'latest'}]",
      );

  final VersionChecker versionChecker;
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
        ['dart', 'pub', 'global', 'activate', 'sidekick', targetVersion],
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
      return versionChecker.getLatestDependencyVersion('sidekick');
    }
    try {
      return Version.parse(rest.first);
    } on FormatException catch (_) {
      throw "'${rest.first}' is not a valid semver version.";
    }
  }
}
