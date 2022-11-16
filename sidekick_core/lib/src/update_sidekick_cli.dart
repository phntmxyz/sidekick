import 'dart:collection';

import 'package:pub_semver/pub_semver.dart';
import 'package:pubspec2/pubspec2.dart' as pub;
import 'package:sidekick_core/sidekick_core.dart';

Future<void> main(List<String> args) async {
  final runner = initializeSidekick(name: args.single); // TODO set mainProjectPath
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
    );

    final template = SidekickTemplate();

    // generate new shell scripts
    template.generateTools(props);
    template.generateEntrypoint(props);

    // generate bin/main.dart
    template.generateBinMainDart(props);
    // generate lib/src/<cli>_project.dart
    template.generateCliProjectDart(props);

    // generate lib/<cli>_sidekick.dart but preserve user imports + added commands
    _generateCliSidekickDart(template, props);

    // generate .gitignore but preserve user changes
    _generateGitignore(props);

    // generate new pubspec.yaml but preserve user changes
    await _generatePubSpec(
      oldPubSpecPath: props.packageLocation.file('pubspec.yaml').path,
      newPubSpecTemplate: props.pubspecYaml,
      destination: props.packageLocation,
    );

    // TODO preserve user changes in analysis_options.yaml
    template.generateAnalysisOptionsYaml(props);
  } finally {
    unmount();
  }
}

/// Generates new pubspec.yaml while preserving values of old pubspec.yaml
Future<void> _generatePubSpec({
  required String oldPubSpecPath,
  required String newPubSpecTemplate,
  required Directory destination,
}) async {
  final oldPubSpec = PubSpec.fromFile(oldPubSpecPath).pubspec;
  final newPubSpec = PubSpec.fromString(newPubSpecTemplate).pubspec;

  final versionRegEx = RegExp(r'\d+\.\d+.\d+');
  final newVersionConstraint = newPubSpec.environment!.sdkConstraint;
  final oldVersionConstraint = oldPubSpec.environment!.sdkConstraint;
  final newVersion = Version.parse(
    versionRegEx.firstMatch(newVersionConstraint.toString())!.group(0)!,
  );
  final oldVersion = Version.parse(
    versionRegEx.firstMatch(oldVersionConstraint.toString())!.group(0)!,
  );

  final mergedPubSpec = oldPubSpec.copy(
    environment: pub.Environment(
      // do not downgrade Dart SDK version if user already upgraded it
      newVersion > oldVersion ? newVersionConstraint : oldVersionConstraint,
      {
        ...?oldPubSpec.environment?.unParsedYaml,
        ...?newPubSpec.environment?.unParsedYaml
      },
    ),
    executables: {
      ...oldPubSpec.executables,
      ...newPubSpec.executables,
    },
    dependencies: {
      ...oldPubSpec.dependencies,
      ...Map.fromEntries(
        newPubSpec.dependencies.entries
            // sidekick_core dependency is already updated by `updateVersionConstraint` in `update_command.dart`
            // do not overwrite it with an older version again
            .where((it) => it.key != 'sidekick_core'),
      ),
    },
    devDependencies: {
      ...oldPubSpec.devDependencies,
      ...newPubSpec.devDependencies,
    },
  );

  await mergedPubSpec.save(destination);
}

/// Generate new .gitignore but preserve user changes
void _generateGitignore(SidekickTemplateProperties props) {
  final gitignoreFile = props.packageLocation.file('.gitignore');
  if (!gitignoreFile.existsSync()) {
    SidekickTemplate().generateGitignore(props);
  } else {
    final oldLines = gitignoreFile.readAsLinesSync();
    final newLines = gitignoreTemplate.split('\n');
    final LinkedHashSet mergedLines =
        LinkedHashSet.from([...oldLines, ...newLines]);
    gitignoreFile.writeAsStringSync(mergedLines.join('\n'));
  }
}

/// Generate lib/<cli>_sidekick.dart but preserve user imports + added commands
void _generateCliSidekickDart(
  SidekickTemplate template,
  SidekickTemplateProperties props,
) {
  final cliSidekickDart = Repository.requiredSidekickPackage.libDir.file(
    '${Repository.requiredSidekickPackage.cliName}_sidekick.dart',
  );
  final oldCliSidekickDartFileContents = cliSidekickDart.readAsStringSync();

  final importRegex = RegExp('import .*?;', dotAll: true);
  final oldImports = importRegex
      .allMatches(oldCliSidekickDartFileContents)
      .map((e) => e.group(0)!)
      .toList();

  final commandRegex = RegExp(r'addCommand.*?\(((.*?)\(.*?\))\)', dotAll: true);

  // e.g. {'DartCommand': 'DartCommand()', 'FooCommand': 'FooCommand(a: 1,\n b: 2,\n)', ...}
  final oldCommands = commandRegex
      .allMatches(oldCliSidekickDartFileContents)
      .associate((match) => MapEntry(match.group(2)!, match.group(1)!));

  template.generateCliSidekickDart(
    props,
    additionalImports: oldImports,
    additionalCommands: oldCommands,
  );
}
