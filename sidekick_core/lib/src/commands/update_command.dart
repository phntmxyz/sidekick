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
    final version = args.rest.isNotEmpty ? args.rest.first : 'latest';

    if (version != 'latest') {
      try {
        Version.parse(version);
      } on FormatException catch (_) {
        usageException("'$version' is not a valid semver version.");
      }
    }

    final versionChecker = VersionChecker(Repository.requiredSidekickPackage);
    // to remember which sidekick_core version the sidekick CLI was generated
    // with, that sidekick_core version is written into the CLI's pubspec.yaml
    // at the path ['sidekick', 'cli_version']

    final versionToInstall = version == 'latest'
        ? await versionChecker.getLatestDependencyVersion('sidekick_core')
        : Version.parse(version);
    final currentSidekickCliVersion =
        versionChecker.getMinimumVersionConstraint(['sidekick', 'cli_version']);
    if (versionToInstall <= currentSidekickCliVersion) {
      print('No need to update because you are already using the '
          'latest sidekick cli version.');
      return;
    }

    // update sidekick_core to load the update script at the necessary version
    versionChecker.updateVersionConstraint(
      pubspecKeys: ['dependencies', 'sidekick_core'],
      newMinimumVersion: versionToInstall,
      pinVersion: true,
    );
    final dartCommand =
        sidekickDartRuntime.isDownloaded() ? sidekickDartRuntime.dart : dart;
    dartCommand(
      ['pub', 'get'],
      workingDirectory: Repository.requiredCliPackage,
    );

    // generate new shell scripts

    // call the latest update script
    // the process running this command uses the old dependency of sidekick_core
    // and its dependencies can't be changed at runtime
    // as a workaround, a new process is started (with `sidekickDartRuntime.dart([updateScript.path])`)
    // which contains the latest sidekick_core dependency
    // and thus the latest update script
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
      dartCommand(
        [
          updateScript.path,
          Repository.requiredSidekickPackage.cliName,
          currentSidekickCliVersion.canonicalizedVersion,
          versionToInstall.canonicalizedVersion,
        ],
        progress: Progress.print(),
      );
      // previously the version was pinned to get the correct version of the
      // update_sidekick_cli script, now we can allow newer versions
      versionChecker.updateVersionConstraint(
        pubspecKeys: ['dependencies', 'sidekick_core'],
        newMinimumVersion: versionToInstall,
      );
    } finally {
      updateScript.deleteSync();
    }
  }
}
