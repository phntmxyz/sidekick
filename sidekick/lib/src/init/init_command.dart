import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dartx/dartx_io.dart';
import 'package:http/http.dart' as http;
import 'package:mason/mason.dart';
import 'package:sidekick/src/init/project_structure_detector.dart';
import 'package:sidekick/src/templates/cli_bundle.g.dart';
import 'package:path/path.dart';

class InitCommand extends Command {
  @override
  String get description => 'Creates a new sidekick CLI';

  @override
  String get name => 'init';

  InitCommand() {
    argParser.addOption(
      'cliName',
      abbr: 'n',
      help:
          'The name of the CLI to be created \nThe `_cli` prefix, will be define automatically',
    );
  }

  @override
  Future<void> run() async {
    final cwd = Directory.current;
    final Directory projectDir = () {
      if (argResults?.rest != null && argResults?.rest.length == 1) {
        final path = argResults?.rest[0];
        if (path != null) {
          final dir = Directory(path);
          if (!dir.existsSync()) {
            throw '${dir.path} is not a valid path to a Dart/Flutter project';
          }
          return dir;
        }
      }
      // fallback to cwd
      return cwd;
    }();
    final cliName = argResults!['cliName'] as String?;
    if (cliName == null) {
      throw 'No cliName provided. Call `sidekick init --cliName <your-name>`';
    }
    print("Generating ${cliName}_sidekick");
    print("In directory: ${projectDir.path}");

    final detector = ProjectStructureDetector();
    final type = detector.detectProjectType(projectDir);

    switch (type) {
      case ProjectStructure.simple:
        createSidekickPackage(path: projectDir, cliName: cliName);
        break;
      case ProjectStructure.multiPackage:
        throw 'The multi package project layout is not yet supported';
      case ProjectStructure.rootWithPackages:
        print('Detected a Dart/Flutter project with a /packages dictionary');
        createSidekickPackage(path: projectDir, cliName: cliName);
        break;
      case ProjectStructure.unknown:
        print(
          'The project structure is not yet supported. '
          'Please open an issue at https://github.com/phntmxyz/sidekick/issues with details about your project structure',
        );
        exit(1);
    }
  }

  Future<void> createSidekickPackage({
    required Directory path,
    required String cliName,
  }) async {
    // init git, required for flutterw
    await gitInit(path);

    // Generate the package code
    final generator = await MasonGenerator.fromBundle(sidekickBundle);
    final generatorTarget = DirectoryGeneratorTarget(path);
    await generator.generate(
      generatorTarget,
      vars: {'name': cliName},
      logger: Logger(),
      fileConflictResolution: FileConflictResolution.overwrite,
    );

    // Make install script executable
    await makeExecutable(
      path.file('packages/${cliName}_sidekick/tool/install.sh'),
    );
    // Make run script executable
    final runScript = path.file('packages/${cliName}_sidekick/tool/run.sh');
    await makeExecutable(runScript);

    // link entrypoint to run script
    // TODO make location configurable
    final entrypointSh = Link(path.file(cliName).path);
    if (entrypointSh.existsSync()) {
      entrypointSh.deleteSync();
    }
    // relative is important here, otherwise it couldn't be checked in
    entrypointSh
        .createSync(relative(runScript.path, from: entrypointSh.parent.path));

    // For now, we install the flutter wrapper to get a dart runtime.
    // TODO Add dart runtime so that dart packages can use sidekick without flutter
    await installFlutterWrapper(path);

    if (!entrypointSh.existsSync()) {
      throw "Could not link run script $runScript $entrypointSh";
    }
  }
}

/// Initializes git via `git init` in [directory]
Future<void> gitInit(Directory directory) async {
  final bool inGitDir =
      Process.runSync('git', ['rev-parse', '--git-dir']).exitCode == 0;
  if (inGitDir) {
    // no need to initialize
    return;
  }
  final Process process =
      await Process.start('git', ['init'], workingDirectory: directory.path);
  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);
  await process.exitCode;
}

/// Installs the [flutter_wrapper](https://github.com/passsy/flutter_wrapper) in
/// [directory] using the provided install script
Future<void> installFlutterWrapper(Directory directory) async {
  const installUri =
      'https://raw.githubusercontent.com/passsy/flutter_wrapper/master/install.sh';
  final content = (await http.get(Uri.parse(installUri))).body;
  final Process process = await Process.start(
    'sh',
    ['-c', content],
    workingDirectory: directory.absolute.path,
  );
  stdout.addStream(process.stdout);
  stderr.addStream(process.stderr);
  await process.exitCode;
}

/// Makes a file executable 'rwxr-xr-x' (755)
Future<void> makeExecutable(FileSystemEntity file) async {
  if (Platform.isWindows) {
    // TODO can this be somehow encoded into the file so that windows users
    //  can generate it and unix users can execute it right away?
    return;
  }
  if (file is Directory) {
    throw "Can't make a Directory executable ($file)";
  }
  if (!file.existsSync()) {
    throw 'File not found ${file.path}';
  }
  final p = await Process.start('chmod', ['755', file.absolute.path]);
  final exitCode = await p.exitCode;
  if (exitCode != 0) {
    throw 'Cloud not set permission 755 for file ${file.path}';
  }
}
