import 'package:dcli/dcli.dart' as dcli;
import 'package:mason/mason.dart';
import 'package:recase/recase.dart';
import 'package:sidekick/src/init/name_suggester.dart';
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
      help: 'The name of the CLI to be created. \n'
          'The `_cli` prefix will be defined automatically.',
    );
    argParser.addOption(
      'initDirectory',
      abbr: 'd',
      help: 'The directory in which the CLI should be created.',
    );
    argParser.addOption(
      'entrypointDirectory',
      abbr: 'e',
      help:
          'The directory in which the CLI entrypoint script should be created. \n'
          'Absolute path or relative from initDirectory.',
    );
    argParser.addOption(
      'cliPackageDirectory',
      abbr: 'c',
      help: 'The directory in which the CLI package should be created. \n'
          'Absolute path or relative from initDirectory.',
    );
    argParser.addOption(
      'mainProjectPath',
      abbr: 'm',
      help:
          'Optionally sets the mainProject, the package that ultimately builds your app. \n'
          'Absolute path or relative from initDirectory, e.g. "packages/my_app".',
    );
  }

  @override
  Future<void> run() async {
    print(
      "Welcome to sidekick. You're about to initialize a sidekick project\n",
    );

    final initDir = Directory(
      argResults!['initDirectory'] as String? ??
          argResults!.rest.firstOrNull ??
          dcli.ask(
            'Enter the directory in which the CLI should be created.\n'
            'Or press enter to use the current directory.\n',
            validator: const DirectoryExistsValidator(),
            defaultValue: canonicalize(Directory.current.path),
          ),
    ).canonicalized;
    if (!initDir.existsSync()) {
      throw 'Directory does not exist: ${initDir.path}';
    }

    final entrypointDir = initDir.cd(
      argResults!['entrypointDirectory'] as String? ??
          dcli.ask(
            '\nEnter the directory in which the entrypoint script should be created.\n'
            'Must be an absolute path or a path relative from initDirectory.\n'
            'Or press enter to use the suggested directory.\n',
            validator: DirectoryIsWithinOrEqualValidator(initDir),
            defaultValue: initDir.path,
          ),
    );
    if (!entrypointDir.isWithinOrEqual(initDir)) {
      throw 'Entrypoint directory ${entrypointDir.path} is not within or equal to ${initDir.path}';
    }

    final cliPackageDir = initDir.cd(
      argResults!['cliPackageDirectory'] as String? ??
          dcli.ask(
            '\nEnter the directory in which the CLI package should be created.\n'
            'Must be an absolute path or a path relative from initDirectory.\n'
            'Or press enter to use the suggested directory.\n',
            validator: DirectoryIsWithinOrEqualValidator(initDir),
            defaultValue: initDir.directory('packages').path,
          ),
    );
    if (!cliPackageDir.isWithinOrEqual(initDir)) {
      throw 'CLI package directory ${cliPackageDir.path} is not within or equal to ${initDir.path}';
    }

    final cliName = argResults!['cliName'] as String? ??
        () {
          print(
            '${dcli.green('Please select a name for your sidekick CLI.')}\n'
            'We know, selecting a name is hard. Here are some suggestions:',
          );
          final suggester = NameSuggester(projectDir: initDir);
          final name = suggester.askUserForName();
          if (name == null) {
            throw 'No cliName provided. Call `sidekick init --cliName <your-name>`';
          }
          return name;
        }();
    if (!isValidPubPackageName(cliName)) {
      throw invalidCliNameErrorMessage;
    }

    final cliNameCollisions = which(cliName).paths
      // Excluding sidekick executables from the throw so you can regenerate an existing sidekick repo
      ..removeWhere((element) => element.contains('.sidekick/bin/$cliName'));
    if (cliNameCollisions.isNotEmpty) {
      throw 'The CLI name $cliName is already taken by an executable on your system see $cliNameCollisions';
    }

    print("\nGenerating ${cliName}_sidekick");

    bool isGitDir(Directory dir) => dir.directory('.git').existsSync();
    final repoRoot = initDir.findParent(isGitDir) ?? initDir;

    final mainProjectPath = argResults!['mainProjectPath'] as String?;
    DartPackage? mainProject = mainProjectPath != null
        ? DartPackage.fromDirectory(initDir.directory(mainProjectPath))
        : null;

    final packages = Repository(root: repoRoot).findAllPackages();

    if (mainProject == null && packages.isNotEmpty) {
      // Ask user for a main project (optional)
      const none = 'None of the above';
      final userSelection = dcli.menu(
        prompt: 'Which of the following packages is your primary app?',
        options: [...packages.map((it) => it.name), none],
        defaultOption: none,
      );
      if (userSelection != none) {
        mainProject = packages.firstWhere((it) => it.name == userSelection);
      }
    }

    await createSidekickPackage(
      cliName: cliName,
      repoRoot: repoRoot,
      packageDir: cliPackageDir,
      entrypointDir: entrypointDir,
      mainProject: mainProject,
      packages: packages,
    );
  }

  /// Generates a custom sidekick CLI
  ///
  /// Required parameters:
  ///   [repoRoot] - parent of the .git directory
  ///   [packageDir] - directory in which the sidekick cli package will be created
  ///   [entrypointDir] - directory in which entrypoint.sh will be created
  ///
  /// Optional parameters:
  ///   [mainProject] - primary project directory (usually an app which depends on all other packages)
  ///   [packages] - list of all packages in the [repoRoot]
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
          'hasMainProject': mainProject != null,
          'mainProjectPath': mainProject != null
              ? relative(mainProject.root.path, from: repoRoot.absolute.path)
              : 'ERROR:no-main-project-path-defined',
          'mainProjectIsRoot':
              mainProject?.root.absolute.path == repoRoot.absolute.path,
          'hasNestedPackagesPath': mainProject != null &&
              !relative(mainProject.root.path, from: repoRoot.absolute.path)
                  .startsWith('packages'),
          'setFlutterSdkPath': Repository(root: repoRoot)
              .findAllPackages()
              .any((package) => package.isFlutterPackage),
        },
        logger: Logger(),
        fileConflictResolution: FileConflictResolution.overwrite,
      );

      // mason doesn't support lists, so we have to add them manually
      _addPackagesToProjectClass(repoRoot, cliPackage, cliName, packages);

      // Extracts info from the pubspec.yaml
      await makeExecutable(cliPackage.file('tool/sidekick_config.sh'));
      // Make runtime downloader executable
      await makeExecutable(cliPackage.file('tool/download_dart.sh'));
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

    // Install flutterw when a Flutter project is detected
    final flutterPackages = [if (mainProject != null) mainProject, ...packages]
        .filter((package) => package.isFlutterPackage);

    if (flutterPackages.isNotEmpty) {
      print('We detected Flutter packages in your project:');
      for (final package in flutterPackages) {
        print('  - ${package.name} '
            'at ${relative(package.root.path, from: repoRoot.absolute.path)}');
      }

      print('\n\n'
          '${dcli.green('Do you want pin the Flutter version of this project with flutterw?\n')}'
          'https://github.com/passsy/flutter_wrapper\n\n'
          'This allows you to use the `$cliName dart` and `$cliName flutter` commands\n');
      final confirmFlutterwInstall = dcli.confirm(
        'Install flutterw?',
        defaultValue: false,
      );
      if (confirmFlutterwInstall) {
        await installFlutterWrapper(entrypointDir);
      }
    }

    // Download the bundled dart runtime for the CLI
    final bundledDart = (SidekickDartRuntime(cliPackage)..download()).dart;

    // TODO add --offline flag that does not upgrade anything
    // make sure sidekick_core is up-to-date
    bundledDart(
      ['pub', 'upgrade', 'sidekick_core'],
      workingDirectory: cliPackage,
    );

    bundledDart(
      ['format', cliPackage.path],
      progress: dcli.Progress.printStdErr(),
    );
  }

  void _addPackagesToProjectClass(
    Directory repoRoot,
    Directory cliPackage,
    String cliName,
    List<DartPackage> packages,
  ) {
    final projectClassFile = cliPackage.file('lib/src/${cliName}_project.dart');

    final packageNames = packages.groupBy((package) => package.name);
    final packageCode = packages.map((package) {
      final path = relative(package.root.path, from: repoRoot.absolute.path);
      final packageNameIsUnique = packageNames[package.name]!.length == 1;
      final packageName = ReCase(packageNameIsUnique ? package.name : path);
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
  final exe = directory.file('flutterw');
  assert(exe.existsSync());
  return exe;
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

extension on Directory {
  bool isWithinOrEqual(Directory dir) {
    return this.isWithin(dir) ||
        // canonicalize is necessary, otherwise '/a/b/c' != '/a/b/c/./.'
        dir.canonicalized.path == canonicalized.path;
  }

  /// Returns the directory you would get when calling `cd` in this directory.
  ///
  /// When [path] is absolute, returns the directory at that path.
  /// Else appends the [path] to this directory.
  Directory cd(String path) =>
      (Directory(path).isAbsolute ? Directory(path) : directory(path))
          .canonicalized;

  /// A [Directory] whose path is the canonicalized path of [this].
  Directory get canonicalized => Directory(canonicalize(path));
}

/// Validates that a given path exists as [Directory].
///
/// Relative paths are resolved from [relativeFrom] or [Directory.current].
class DirectoryExistsValidator extends dcli.AskValidator {
  const DirectoryExistsValidator([this.relativeFrom]);

  final Directory? relativeFrom;

  @override
  String validate(String line) {
    final currentDirectory = relativeFrom ?? Directory.current;
    final dir = currentDirectory.cd(line);
    if (!dir.existsSync()) {
      throw AskValidatorException(
          'The directory $line does not exist (neither as absolute path, nor '
          'as path relative from ${currentDirectory.canonicalized.path}.');
    }
    return line;
  }
}

/// Validates that a given path is a directory within or equal to [root]
class DirectoryIsWithinOrEqualValidator extends dcli.AskValidator {
  DirectoryIsWithinOrEqualValidator(this.root);

  final Directory root;

  @override
  String validate(String line) {
    final dir = root.cd(line);
    if (!dir.isWithinOrEqual(root)) {
      throw AskValidatorException(
        'The directory ${dir.path} must be within or equal to ${root.canonicalized.path}.',
      );
    }
    return line;
  }
}
