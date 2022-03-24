import 'package:dcli/dcli.dart' as dcli;
import 'package:mason/mason.dart';
import 'package:recase/recase.dart';
import 'package:sidekick/src/init/name_suggester.dart';
import 'package:sidekick/src/init/project_structure_detector.dart';
import 'package:sidekick/src/templates/entrypoint_bundle.g.dart';
import 'package:sidekick/src/templates/package_bundle.g.dart';
import 'package:sidekick_core/sidekick_core.dart';

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
          'The name of the CLI to be created \nThe `_cli` prefix will be defined automatically',
    );
  }

  @override
  Future<void> run() async {
    print(
      "Welcome to sidekick. You're about to initialize a sidekick project\n",
    );

    final cwd = Directory.current;
    // TODO make package location and entrypoint location configurable
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
    final cliName = (argResults!['cliName'] as String? ??
            () {
              print(
                '${dcli.green('Please select a name for your sidekick CLI.')}\n'
                'We know, selecting a name is hard. Here are some suggestions:',
              );
              final suggester = NameSuggester(projectDir: projectDir);
              final name = suggester.askUserForName();
              if (name == null) {
                throw 'No cliName provided. Call `sidekick init --cliName <your-name>`';
              }
              return name;
            }())
        .toLowerCase();
    print("Generating ${cliName}_sidekick");

    final detector = ProjectStructureDetector();
    final type = detector.detectProjectType(projectDir);

    switch (type) {
      case ProjectStructure.simple:
        await createSidekickPackage(
          cliName: cliName,
          repoRoot: projectDir,
          packageDir: projectDir.directory('packages'),
          entrypointDir: projectDir,
          mainProject: DartPackage.fromDirectory(projectDir),
        );
        break;
      case ProjectStructure.multiPackage:
        final List<DartPackage> packages = projectDir
            .directory('packages')
            .listSync()
            .whereType<Directory>()
            .map((it) => DartPackage.fromDirectory(it))
            .filterNotNull()
            .sortedBy((it) => it.name)
            .toList();

        const none = 'None of the above';
        final userSelection = dcli.menu(
          prompt: 'Which of the following package is your primary app?',
          options: [...packages.map((it) => it.name), none],
          defaultOption: none,
        );
        DartPackage? mainProject;
        if (userSelection == none) {
          mainProject = null;
        } else {
          mainProject = packages.firstWhere((it) => it.name == userSelection);
        }
        await createSidekickPackage(
          cliName: cliName,
          repoRoot: projectDir,
          packageDir: projectDir.directory('packages'),
          entrypointDir: projectDir,
          mainProject: mainProject,
          packages: packages,
        );
        break;
      case ProjectStructure.rootWithPackages:
        print('Detected a Dart/Flutter project with a /packages dictionary');
        await createSidekickPackage(
          cliName: cliName,
          repoRoot: projectDir,
          packageDir: projectDir.directory('packages'),
          entrypointDir: projectDir,
          mainProject: DartPackage.fromDirectory(projectDir),
        );
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
    required String cliName,
    required Directory repoRoot,
    required Directory packageDir,
    required Directory entrypointDir,
    DartPackage? mainProject,
    List<DartPackage> packages = const [],
  }) async {
    // init git, required for flutterw
    await gitInit(repoRoot);

    final Directory cliPackage = packageDir.directory('${cliName}_sidekick');
    {
      // Generate the package code
      final generator = await MasonGenerator.fromBundle(packageBundle);
      final generatorTarget = DirectoryGeneratorTarget(cliPackage);
      await generator.generate(
        generatorTarget,
        vars: {
          'name': cliName,
          if (mainProject != null)
            'mainProjectPath':
                relative(mainProject.root.path, from: repoRoot.absolute.path),
        },
        logger: Logger(),
        fileConflictResolution: FileConflictResolution.overwrite,
      );

      // mason doesn't support lists, so we have to add them manually
      _addPackagesToProjectClass(repoRoot, cliPackage, cliName, packages);

      // Make install script executable
      await makeExecutable(cliPackage.file('tool/install.sh'));
      // Make run script executable
      await makeExecutable(cliPackage.file('tool/run.sh'));
    }

    {
      // Generate entrypoint
      final generator = await MasonGenerator.fromBundle(entrypointBundle);
      final generatorTarget = DirectoryGeneratorTarget(entrypointDir);
      await generator.generate(
        generatorTarget,
        vars: {
          'packagePath': relative(cliPackage.path, from: entrypointDir.path),
        },
        logger: Logger(),
        fileConflictResolution: FileConflictResolution.overwrite,
      );
      final generatedEntrypoint = entrypointDir.file('entrypoint.sh');
      final File entrypoint = entrypointDir.file(cliName);
      generatedEntrypoint.renameSync(entrypoint.path);
      await makeExecutable(entrypoint);
    }

    // For now, we install the flutter wrapper to get a dart runtime.
    // TODO Add dart runtime so that dart packages can use sidekick without flutter
    final flutterw = await installFlutterWrapper(entrypointDir);

    // make sure sidekick_core is up-to-date
    upgradeSidekickDependencies(
      flutterw,
      cliPackage,
      packages: ['sidekick_core'],
    );
  }

  void _addPackagesToProjectClass(
    Directory repoRoot,
    Directory cliPackage,
    String cliName,
    List<DartPackage> packages,
  ) {
    final projectClassFile = cliPackage.file('lib/src/${cliName}_project.dart');

    final packageCode = packages.map((package) {
      final path = relative(package.root.path, from: repoRoot.absolute.path);
      final packageName = ReCase(package.name);
      return "DartPackage get ${packageName.camelCase}Package => DartPackage.fromDirectory(root.directory('$path'))!;";
    }).toList();

    final code = '''
  
  ${packageCode.join('\n\n  ')}
    ''';

    projectClassFile.replaceSectionWith(
      startTag: '/// packages',
      endTag: '\n',
      content: code,
    );
    projectClassFile.replaceFirst('/// packages', '');
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
Future<File> installFlutterWrapper(Directory directory) async {
  writeAndRunShellScript(
    r'sh -c "$(curl -fsSL https://raw.githubusercontent.com/passsy/flutter_wrapper/master/install.sh)"',
    workingDirectory: directory,
  );
  return directory.file('flutterw');
}

/// Upgrade dependencies of a sidekick cli
void upgradeSidekickDependencies(
  File flutterw,
  Directory sidekickCliPackage, {
  List<String> packages = const [],
}) {
  final relFlutterw = relative(flutterw.path, from: sidekickCliPackage.path);
  dcli.run(
    'sh $relFlutterw pub upgrade ${packages.join(' ')}',
    workingDirectory: sidekickCliPackage.path,
  );
}

/// Makes a file executable 'rwxr-xr-x' (755)
Future<void> makeExecutable(FileSystemEntity file) async {
  if (file is Directory) {
    throw "Can't make a Directory executable ($file)";
  }
  if (Platform.isWindows) {
    // The windows file system works differently than unix based ones. exe files are automatically executable
    // But when generating sidekick on windows, it should also be executable on unix systems on checkout.
    // This is done by telling git about the file being executable.
    // https://www.scivision.dev/git-windows-chmod-executable/
    final p = await Process.start(
      'git',
      ['update-index', '--chmod=+x', '--add', file.path],
    );
    final exitCode = await p.exitCode;
    if (exitCode != 0) {
      throw 'Could not set git file permission for unix systems for file ${file.path}';
    }
    return;
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
