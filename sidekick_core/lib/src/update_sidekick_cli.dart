import 'package:sidekick_core/sidekick_core.dart';

Future<void> main(List<String> args) async {
  final runner= initializeSidekick(name: args.single)..mount();
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
  );

  final template = SidekickTemplate();

  template.generateTools(props);
  template.generateEntrypoint(props);
}
