import 'package:pub_semver/pub_semver.dart';
import 'package:recase/recase.dart';

import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/template/download_dart.sh.template.dart';
import 'package:sidekick_core/src/template/entrypoint.template.dart';
import 'package:sidekick_core/src/template/install.sh.template.dart';
import 'package:sidekick_core/src/template/run.sh.template.dart';
import 'package:sidekick_core/src/template/sidekick_config.sh.template.dart';

class SidekickTemplate {
  void generate(SidekickTemplateProperties props) {
    generateEntrypoint(props);
    generatePackage(props);
    generateTools(props);
  }

  void generateEntrypoint(SidekickTemplateProperties props) {
    final path = relative(
      props.packageLocation.path,
      from: props.entrypointLocation.parent.path,
    );
    final entrypoint = entrypointTemplate(packagePath: path);
    props.entrypointLocation.writeAsStringSync(entrypoint);
    props.entrypointLocation.makeExecutable();
  }

  void generateTools(SidekickTemplateProperties props) {
    props.packageLocation.file('tool/download_dart.sh')
      ..createSync(recursive: true)
      ..writeAsStringSync(downloadDartSh)
      ..makeExecutable();
    props.packageLocation.file('tool/install.sh')
      ..writeAsStringSync(installSh(cliName: props.name))
      ..makeExecutable();
    props.packageLocation.file('tool/run.sh')
      ..writeAsStringSync(runSh)
      ..makeExecutable();
    props.packageLocation.file('tool/sidekick_config.sh')
      ..writeAsStringSync(sidekickConfigSh)
      ..makeExecutable();
  }

  void generatePackage(SidekickTemplateProperties props) {
    generateGitignore(props);
    props.packageLocation
        .file('pubspec.yaml')
        .writeAsStringSync(props.pubspecYaml);
    generateAnalysisOptionsYaml(props);

    generateBinMainDart(props);
    generateCliProjectDart(props);
    generateCliSidekickDart(props);

    props.packageLocation.file('lib/src/commands/clean_command.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(props.cleanCommandDart());
  }

  void generateBinMainDart(SidekickTemplateProperties props) {
    props.packageLocation.file('bin/main.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(props.binMainDart());
  }

  void generateCliProjectDart(SidekickTemplateProperties props) {
    props.packageLocation
        .file('lib/src/${props.name.snakeCase}_project.dart')
        .writeAsStringSync(props.cliProjectDart());
  }

  void generateCliSidekickDart(
    SidekickTemplateProperties props, {
    List<String> additionalImports = const [],
    Map<String, String> additionalCommands = const {},
  }) {
    props.packageLocation
        .file('lib/${props.name.snakeCase}_sidekick.dart')
        .writeAsStringSync(
          props.cliSidekickDart(
            additionalImports: additionalImports,
            additionalCommands: additionalCommands,
          ),
        );
  }

  void generateGitignore(SidekickTemplateProperties props) {
    props.packageLocation.file('.gitignore')
      ..createSync(recursive: true)
      ..writeAsStringSync(gitignoreTemplate);
  }

  void generateAnalysisOptionsYaml(SidekickTemplateProperties props) {
    props.packageLocation
        .file('analysis_options.yaml')
        .writeAsStringSync(analysisOptionsYamlTemplate);
  }
}

class SidekickTemplateProperties {
  /// Name of the CLI.
  ///
  /// Do not rename it to `cliName` which would conflict with [cliName]
  final String name;

  /// Where the entrypoint will be created
  final File entrypointLocation;

  /// Where the sidekick package will be created.
  final Directory packageLocation;

  /// When there's a flutter package that requires a flutter sdk
  final bool shouldSetFlutterSdkPath;

  /// When the dart package is located in root of the repo
  final bool isMainProjectRoot;

  /// true when a /packages directory exists
  final bool hasNestedPackagesPath;

  /// Path to main project, relative from repo root
  final String? mainProjectPath;

  /// The version of the sidekick CLI generating this template
  final Version sidekickVersion;

  const SidekickTemplateProperties({
    required this.name,
    required this.entrypointLocation,
    required this.packageLocation,
    required this.mainProjectPath,
    required this.shouldSetFlutterSdkPath,
    required this.isMainProjectRoot,
    required this.hasNestedPackagesPath,
    required this.sidekickVersion,
  });
}

extension on SidekickTemplateProperties {
  String binMainDart() {
    return '''
import 'package:${name.snakeCase}_sidekick/${name.snakeCase}_sidekick.dart';

Future<void> main(List<String> arguments) async {
  await run${name.titleCase}(arguments);
}
''';
  }

  String cliProjectDart() {
    if (isMainProjectRoot) {
      return '''
import 'package:sidekick_core/sidekick_core.dart';

class ${name.titleCase}Project extends DartPackage {
  factory ${name.titleCase}Project(Directory root) {
    final package = DartPackage.fromDirectory(root)!;
    return ${name.titleCase}Project._(package.root, package.name);
  }

  ${name.titleCase}Project._(Directory root, String name) : super.flutter(root, name);

  /// packages

  File get flutterw => root.file('flutterw');

  List<DartPackage>? _packages;
  List<DartPackage> get allPackages {
    return _packages ??= root
        ${hasNestedPackagesPath ? ".directory('$mainProjectPath')" : ''}
        .directory('packages')
        .listSync()
        .whereType<Directory>()
        .mapNotNull((it) => DartPackage.fromDirectory(it))
        .toList()
        ${isMainProjectRoot ? '..add(this)' : ''};
  }
}
    
''';
    } else {
      return '''
import 'package:sidekick_core/sidekick_core.dart';

class ${name.titleCase}Project {
  ${name.titleCase}Project(this.root);

  final Directory root;
  /// packages

  File get flutterw => root.file('flutterw');

  List<DartPackage>? _packages;
  List<DartPackage> get allPackages {
    return _packages ??= root
        ${hasNestedPackagesPath ? ".directory('$mainProjectPath')" : ''}
        .directory('packages')
        .listSync()
        .whereType<Directory>()
        .mapNotNull((it) => DartPackage.fromDirectory(it))
        .toList()
        ${isMainProjectRoot ? '..add(this)' : ''};
  }
}

''';
    }
  }

  /// [additionalCommands] e.g. {'DartCommand': 'DartCommand()', 'FooCommand': 'FooCommand(a: 1,\n b: 2,\n)', ...}
  String cliSidekickDart({
    List<String> additionalImports = const [],
    Map<String, String> additionalCommands = const {},
  }) {
    // merge default imports with additional imports
    final defaultImports = [
      "import 'dart:async';",
      "",
      "import 'package:${name.snakeCase}_sidekick/src/commands/clean_command.dart';",
      "import 'package:${name.snakeCase}_sidekick/src/${name.snakeCase}_project.dart';",
      "import 'package:sidekick_core/sidekick_core.dart';",
    ];
    final allImports = [
      ...defaultImports,
      for (final additionalImport in additionalImports)
        if (!defaultImports.contains(additionalImport)) additionalImport,
    ].join('\n');

    // merge default commands with additional commands
    final defaultCommands = {
      if (shouldSetFlutterSdkPath) 'FlutterCommand': 'FlutterCommand()',
      'DartCommand': 'DartCommand()',
      'DepsCommand': 'DepsCommand()',
      'CleanCommand': 'CleanCommand()',
      'DartAnalyzeCommand': 'DartAnalyzeCommand()',
      'SidekickCommand': 'SidekickCommand()',
    };

    final allCommands = {
      ...additionalCommands,
      ...defaultCommands,
    }.values;

    final projectRoot = isMainProjectRoot != true
        ? 'runner.repository.root'
        : 'runner.mainProject!.root';

    return '''
$allImports

late ${name.titleCase}Project ${name.snakeCase}Project;

Future<void> run${name.titleCase}(List<String> args) async {
  final runner = initializeSidekick(
    name: '${name.snakeCase}',
    ${mainProjectPath != null ? "mainProjectPath: '$mainProjectPath'," : ''}
    ${shouldSetFlutterSdkPath ? 'flutterSdkPath: systemFlutterSdkPath(),' : 'dartSdkPath: systemDartSdkPath(),'}
  );

  ${name.snakeCase}Project = ${name.titleCase}Project($projectRoot);
  runner
${allCommands.map((cmd) => '    ..addCommand($cmd)').join('\n')};

  if (args.isEmpty) {
    print(runner.usage);
    return;
  }

  try {
    return await runner.run(args);
  } on UsageException catch (e) {
    print(e.usage);
    exit(64); // usage error
  }
}

''';
  }

  String cleanCommandDart() {
    return '''
import 'package:sidekick_core/sidekick_core.dart';

class CleanCommand extends Command {
  @override
  final String description = 'Cleans the project';

  @override
  final String name = 'clean';

  @override
  Future<void> run() async {
    ${mainProjectPath != null ? "flutter(['clean'], workingDirectory: mainProject?.root);" : ''}
    // TODO Please add your own project clean logic here

    print('✔️Cleaned project');
  }
}
  
''';
  }
}

extension PubspecYaml on SidekickTemplateProperties {
  String get pubspecYaml {
    return '''
name: ${name.snakeCase}_sidekick
description: Sidekick CLI for $name
version: 0.0.1
publish_to: none

environment:
  sdk: '>=2.14.0 <3.0.0'

executables:
  main:

dependencies:
  sidekick_core: '>=0.10.0 <1.0.0'

dev_dependencies:
  lint: ^1.5.3

# generated code, do not edit this manually
sidekick:
  generator_version: ${sidekickVersion.canonicalizedVersion}
''';
  }
}

const String gitignoreTemplate = '''
# Files and directories created by pub
.dart_tool/
.packages

# Conventional directory for build outputs
build/

# Directory created by dartdoc
doc/api/
''';

const String analysisOptionsYamlTemplate = '''
include: package:lint/analysis_options.yaml

linter:
  rules:
    avoid_print: false
''';
