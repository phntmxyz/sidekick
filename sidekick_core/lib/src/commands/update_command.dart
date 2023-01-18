import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/version_checker.dart';

/// Updates the sidekick cli
class UpdateCommand extends Command {
  @override
  final String description = 'Updates the sidekick cli';

  @override
  final String name = 'update';

  @override
  String get invocation => super.invocation.replaceFirst(
        '[arguments]',
        "[{<version>, 'latest'}]",
      );

  @override
  Future<void> run() async {
    final args = argResults!;

    final Version? version = args.versionFromRest(
      formatError: (rest) {
        usageException("'$rest' is not a valid semver version.");
      },
    );

    final versionToInstall = version ??
        await VersionChecker.getLatestDependencyVersion('sidekick_core');

    // to remember which sidekick_core version the sidekick CLI was generated
    // with, that sidekick_core version is written into the CLI's pubspec.yaml
    // at the path ['sidekick', 'cli_version']
    final currentSidekickCliVersion =
        VersionChecker.getMinimumVersionConstraint(
              Repository.requiredSidekickPackage,
              ['sidekick', 'cli_version'],
            ) ??
            Version.none;

    if (versionToInstall <= currentSidekickCliVersion) {
      print('No need to update because you are already using the '
          'latest sidekick cli version.');
      return;
    }

    // kick of the update process
    updateSidekickCli(from: currentSidekickCliVersion, to: versionToInstall);
  }

  /// Updates the sidekick cli to the new [to] version by loading `sidekick_core`
  /// with version `to` from pub and running the bundled update script from that
  /// package version.
  ///
  /// The update script is located at `lib/src/update_sidekick_cli.dart`
  void updateSidekickCli({required Version from, required Version to}) {
    // update sidekick_core to load the update script at the necessary version
    VersionChecker.updateVersionConstraint(
      package: Repository.requiredSidekickPackage,
      pubspecKeys: ['dependencies', 'sidekick_core'],
      newMinimumVersion: to,
      // make sure we get the update script exactly at the specified version
      pinVersion: true,
    );
    _dartCommand(
      ['pub', 'get'],
      workingDirectory: Repository.requiredCliPackage,
    );

    // run the update script (`update_sidekick_cli.dart`) from sidekick_core at
    // the exact version [to]
    startUpdateScriptProcess(from, to);

    // previously the version was pinned to get the correct version of the
    // update_sidekick_cli script, now we can allow newer versions again
    VersionChecker.updateVersionConstraint(
      package: Repository.requiredSidekickPackage,
      pubspecKeys: ['dependencies', 'sidekick_core'],
      newMinimumVersion: to,
    );
    try {
      _dartCommand(
        ['pub', 'get'],
        workingDirectory: Repository.requiredCliPackage,
        progress: Progress.devNull(),
      );
    } catch (e) {
      // This pub get is a nice to have, and it doesn't matter if it fails or
      // not. It may fail when the Dart SDK version has been updated, because
      // `_dartCommand` still uses the "old" Dart SDK.
      // The new SDK will be downloaded with the next execution.

      // For all other errors: The become visible the next time the cli is executed
    }
  }

  /// Runs the update script `update_sidekick_cli.dart` in a new process using
  /// the `sidekick_core` package at the exact version that is specified in
  /// pubspec.lock
  ///
  /// The current process - running `sidekick update` - can't access code of other
  /// version of sidekick_core. Dependencies can't be changed at runtime.
  /// This workaround allows accessing any version of sidekick_core.
  ///
  /// Make sure to update the sidekick_core dependency before starting this
  /// process.
  void startUpdateScriptProcess(Version from, Version to) {
    final updateScript =
        Repository.requiredSidekickPackage.buildDir.file('update.dart')
          ..createSync(recursive: true)
          ..writeAsStringSync('''
  import 'package:sidekick_core/src/update_sidekick_cli.dart' as update;
  Future<void> main(List<String> args) async {
  await update.main(args);
  }
  ''');
    try {
      _dartCommand(
        [
          updateScript.path,
          Repository.requiredSidekickPackage.cliName,
          from.canonicalizedVersion,
          to.canonicalizedVersion,
        ],
        progress: Progress.print(),
      );
    } finally {
      updateScript.deleteSync();
    }
  }
}

extension on ArgResults {
  Version? versionFromRest({void Function(String rest)? formatError}) {
    if (rest.isEmpty) {
      return null;
    }
    if (rest.first == 'latest') {
      return null;
    }
    try {
      return Version.parse(rest.first);
    } on FormatException catch (_) {
      formatError?.call(rest.join(' '));
      return null;
    }
  }
}

/// Executes a dart command, usually from the embedded Dart SDK
/// [SidekickDartRuntime.dart] or [dart] in case the sidekick CLI was created
/// before `sidekick_core: 0.10.0`.
///
/// This workaround is only required within this command. If any other command
/// fails because it is missing the embedded Dart SDK, the user should update
/// their cli.
void Function(
  List<String> args, {
  Progress? progress,
  Directory? workingDirectory,
}) get _dartCommand {
  return sidekickDartRuntime.isDownloaded() ? sidekickDartRuntime.dart : dart;
}
