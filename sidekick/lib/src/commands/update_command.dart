import 'dart:async';

import 'package:dcli/dcli.dart';
import 'package:sidekick/sidekick.dart';
import 'package:sidekick_core/sidekick_core.dart' hide version;

/// Updates the global sidekick CLI
///
/// A target version can be specified as positional argument. If no version is
/// given, updates to the latest available version.
class UpdateCommand extends Command {
  @override
  final String description = 'Updates the global sidekick CLI';

  @override
  final String name = 'update';

  @override
  String get invocation => super.invocation.replaceFirst(
        '[arguments]',
        "[{<version>, 'latest'}]",
      );

  @override
  Future<void> run() async {
    final targetVersion = await argResults!.version;

    final isUpToDate = version == targetVersion;
    if (isUpToDate) {
      print('No need to update because the global sidekick CLI already is '
          'at the specified or latest version ($targetVersion).');
      return;
    }

    try {
      startFromArgs(
        'dart',
        ['pub', 'global', 'activate', 'sidekick', targetVersion.toString()],
        progress: Progress.devNull(),
      );
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
}

extension on ArgResults {
  FutureOr<Version> get version {
    if (rest.isEmpty || rest.first == 'latest') {
      return const VersionChecker().getLatestDependencyVersion('sidekick');
    }
    try {
      return Version.parse(rest.first);
    } on FormatException catch (_) {
      throw "'${rest.first}' is not a valid semver version.";
    }
  }
}
