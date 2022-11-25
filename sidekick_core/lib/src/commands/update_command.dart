import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/sidekick_version_checker.dart';

/// Updates the sidekick cli
class UpdateCommand extends Command {
  @override
  final String description = 'Updates the sidekick cli';

  @override
  final String name = 'update';

  @override
  Future<void> run() async {
    const sidekickVersionChecker = SidekickVersionChecker();
    // to remember which sidekick_core version the sidekick CLI was generated
    // with, that sidekick_core version is written into the CLI's pubspec.yaml
    // at the path ['sidekick', 'cli_version']

    final latestSidekickCoreVersion =
        await sidekickVersionChecker.getLatestPackageVersion('sidekick_core');
    final currentSidekickCliVersion = sidekickVersionChecker
        .getCurrentMinimumPackageVersion(['sidekick', 'cli_version']);
    if (latestSidekickCoreVersion == currentSidekickCliVersion) {
      print('No need to update because you are already using the '
          'latest sidekick cli version.');
      return;
    }

    // update sidekick_core to load the latest update script
    await sidekickVersionChecker
        .updateVersionConstraintToLatest('sidekick_core');
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
          latestSidekickCoreVersion.canonicalizedVersion,
        ],
        progress: Progress.print(),
      );
    } finally {
      updateScript.deleteSync();
    }
  }
}
