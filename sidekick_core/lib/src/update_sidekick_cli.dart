import 'package:pub_semver/pub_semver.dart';
import 'package:sidekick_core/sidekick_core.dart';

Future<void> main(List<String> args) async {
  final sidekickCliName = args[0];
  final currentSidekickVersion = Version.parse(args[1]);
  final latestSidekickVersion = Version.parse(args[2]);

  print(
    grey(
      'Updating sidekick CLI $sidekickCliName from version $currentSidekickVersion to $latestSidekickVersion ...',
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
      sidekickVersion: latestSidekickVersion,
    );

    final template = SidekickTemplate();

    // generate new shell scripts
    template.generateTools(props);
    template.generateEntrypoint(props);

    // TODO(update-feature): run further steps necessary for update from [currentSidekickVersion] to [latestSidekickVersion]
  } finally {
    unmount();
  }
}
