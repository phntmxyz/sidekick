import 'package:dcli/dcli.dart' as dcli;
import 'package:recase/recase.dart';
import 'package:sidekick/src/util/dcli_ask_validators.dart';
import 'package:sidekick/src/util/directory_extension.dart';
import 'package:sidekick/src/util/name_suggester.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/sidekick_core.dart' as core;

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
      'entrypointDirectory',
      abbr: 'e',
      help:
          'The directory in which the CLI entrypoint script should be created.',
    );
    argParser.addOption(
      'cliPackageDirectory',
      abbr: 'c',
      help: 'The directory in which the CLI package should be created. \n'
          'This directory must be within the entrypointDirectory, '
          'or if the entrypointDirectory is inside a git repository, '
          'the cliPackageDirectory must be within the same git repository.',
    );
    argParser.addOption(
      'mainProjectPath',
      abbr: 'm',
      help:
          'Optionally sets the mainProject, the package that ultimately builds your app. \n'
          'This directory must be within the entrypointDirectory, '
          'or if the entrypointDirectory is inside a git repository, '
          'the mainProjectPath must be within the same git repository.',
    );
  }

  @override
  Future<void> run() async {
    print(
      "Welcome to sidekick. You're about to initialize a sidekick project\n",
    );

    final entrypointDir = Directory(
      argResults!['entrypointDirectory'] as String? ??
          argResults!.rest.firstOrNull ??
          dcli.ask(
            '\nEnter the directory in which the entrypoint script should be created.\n'
            'Or press enter to use the current directory.\n',
            validator: const DirectoryExistsValidator(),
            defaultValue: Directory.current.path,
          ),
    ).canonicalized;
    if (!entrypointDir.existsSync()) {
      throw 'Entrypoint directory ${entrypointDir.path} does not exist';
    }

    final Directory projectRoot = entrypointDir;

    final cliPackageDir = Directory(
      argResults!['cliPackageDirectory'] as String? ??
          dcli.ask(
            '\nEnter the directory in which the CLI package should be created.\n'
            'Must be an absolute path or a path '
            'relative to the repository root (${entrypointDir.path}).\n'
            'Or press enter to use the suggested directory.\n',
            validator: DirectoryIsWithinOrEqualValidator(projectRoot),
            defaultValue: projectRoot.directory('packages').path,
          ),
    );
    if (!cliPackageDir.isWithinOrEqual(projectRoot)) {
      throw 'CLI package directory ${cliPackageDir.path} is not within or equal to ${projectRoot.path}';
    }

    final mainProjectPath = argResults!['mainProjectPath'] as String?;
    DartPackage? mainProject = mainProjectPath != null
        ? DartPackage.fromDirectory(Directory(mainProjectPath))
        : DartPackage.fromDirectory(projectRoot);
    if (mainProjectPath != null && mainProject == null) {
      throw 'mainProjectPath was given, but no DartPackage could be found at the given path $mainProjectPath';
    }
    if (mainProject != null && !mainProject.root.isWithinOrEqual(projectRoot)) {
      throw 'Main project ${mainProject.root.path} is not within or equal to ${projectRoot.path}';
    }

    final cliName = argResults!['cliName'] as String? ??
        () {
          print(
            '${dcli.green('Please select a name for your sidekick CLI.')}\n'
            'We know, selecting a name is hard. Here are some suggestions:',
          );
          final suggester = NameSuggester(projectDir: projectRoot);
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

    final packages = findAllPackages(projectRoot);

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
      repoRoot: projectRoot,
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

    final entrypoint = entrypointDir.file(cliName.snakeCase);
    final props = SidekickTemplateProperties(
      name: cliName,
      mainProjectPath: mainProject != null
          ? relative(mainProject.root.path, from: repoRoot.absolute.path)
          : null,
      shouldSetFlutterSdkPath:
          findAllPackages(repoRoot).any((package) => package.isFlutterPackage),
      entrypointLocation: entrypoint,
      packageLocation: cliPackage,
    );
    SidekickTemplate().generate(props);

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
}

/// Initializes git via `git init` in [directory]
Future<void> gitInit(Directory directory) async {
  final bool inGitDir = Process.runSync(
        'git',
        ['rev-parse', '--git-dir'],
        workingDirectory: directory.path,
      ).exitCode ==
      0;
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
