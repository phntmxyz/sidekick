import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/update_command.dart';

/// Updates a sidekick CLI
///
/// This function is called by [UpdateCommand]
/// and receives the following arguments:
///   1. name of the sidekick cli to update
///   2. current version of the sidekick cli
///   3. target version of the sidekick cli
Future<void> main(List<String> args) async {
  final sidekickCliName = args[0];
  final currentSidekickCliVersion = Version.parse(args[1]);
  final latestSidekickCoreVersion = Version.parse(args[2]);

  print(
    grey(
      'Updating sidekick CLI $sidekickCliName from version $currentSidekickCliVersion to $latestSidekickCoreVersion ...',
    ),
  );

  final runner = initializeSidekick(name: sidekickCliName);
  final unmount = runner.mount();
  try {
    bool isGitDir(Directory dir) => dir.directory('.git').existsSync();
    final entrypointDir = Repository.requiredEntryPoint.parent;
    final repoRoot = entrypointDir.findParent(isGitDir) ?? entrypointDir;
    final mainProjectPath = mainProject != null
        ? relative(mainProject!.root.path, from: repoRoot.absolute.path)
        : null;
    final isMainProjectRoot =
        mainProject?.root.absolute.path == repoRoot.absolute.path;
    final hasNestedPackagesPath = mainProject != null &&
        !relative(mainProject!.root.path, from: repoRoot.absolute.path)
            .startsWith('packages');

    final props = SidekickTemplateProperties(
      name: Repository.requiredSidekickPackage.cliName,
      entrypointLocation: Repository.requiredEntryPoint,
      packageLocation: Repository.requiredCliPackage,
      mainProjectPath: mainProjectPath,
      shouldSetFlutterSdkPath: runner.commands.containsKey('flutter'),
      isMainProjectRoot: isMainProjectRoot,
      hasNestedPackagesPath: hasNestedPackagesPath,
      sidekickCliVersion: latestSidekickCoreVersion,
    );

    final template = SidekickTemplate();

    // generate new shell scripts
    template.generateTools(props);
    template.generateEntrypoint(props);

    // TODO(update-feature): run further steps necessary for update from [currentSidekickVersion] to [latestSidekickVersion]

    // update sidekick: cli_version: <version> in pubspec.yaml to signalize
    // that update has completed successfully
    const VersionChecker().updateVersionConstraint(
      package: Repository.requiredSidekickPackage,
      pubspecKeys: ['sidekick', 'cli_version'],
      newMinimumVersion: latestSidekickCoreVersion,
      pinVersion: true,
    );
    print(
      green(
        'Successfully updated sidekick CLI $cliName from version $currentSidekickCliVersion to $latestSidekickCoreVersion!',
      ),
    );
  } catch (_) {
    print(
      red(
        'There was an error updating sidekick CLI $cliName from version $currentSidekickCliVersion to $latestSidekickCoreVersion.',
      ),
    );
    rethrow;
  } finally {
    unmount();
  }
}
