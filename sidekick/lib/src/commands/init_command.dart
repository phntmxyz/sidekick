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

    final projectRoot = Directory(
      argResults!['entrypointDirectory'] as String? ??
          argResults!.rest.firstOrNull ??
          () {
            print(
              '${green('Enter the directory in which the entrypoint script should be created.')}\n'
              'Or press enter to use the current directory.',
            );
            final answer = dcli.ask(
              'Set entrypoint directory:',
              validator: const DirectoryExistsValidator(),
              defaultValue: Directory.current.path,
            );
            print('');
            return answer;
          }(),
    ).canonicalized;
    if (!projectRoot.existsSync()) {
      throw 'Entrypoint directory ${projectRoot.path} does not exist';
    }

    final cliPackageDir = Directory(
      argResults!['cliPackageDirectory'] as String? ??
          () {
            print(
              '${green('Enter the directory in which the CLI package should be created.')}\n'
              'Must be an absolute path or a path '
              'relative to the repository root (${projectRoot.path}).\n'
              'Or press enter to use the suggested directory.\n',
            );
            final answer = dcli.ask(
              'Set CLI package directory:',
              validator: DirectoryIsWithinOrEqualValidator(projectRoot),
              defaultValue: projectRoot.directory('packages').path,
            );
            print('');
            return answer;
          }(),
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

    print("\n${green("Generating ${cliName}_sidekick")}");

    final packages = Repository(root: projectRoot).findAllPackages();

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
      projectRoot: projectRoot,
      packageDir: cliPackageDir,
      entrypointDir: projectRoot,
      mainProject: mainProject,
      packages: packages,
    );
    print("Code generation successful");

    final entrypoint = projectRoot.file(cliName);

    // Install flutterw when a Flutter project is detected
    final flutterPackages = [if (mainProject != null) mainProject, ...packages]
        .filter((package) => package.isFlutterPackage)
        .toList();

    if (flutterPackages.isNotEmpty) {
      print(
          'Sidekick detected (${flutterPackages.length}) Flutter packages in your project.\n');
      print(
        "It's recommended to bind an exact Flutter version to your project "
        "and share the same version with your coworkers and CI. There are two ways to accomplish this:\n"
        " - Use FVM (https://fvm.app/)\n"
        " - Use flutterw (https://github.com/passsy/flutter_wrapper)\n",
      );

      print(
        dcli.green(
          'Do you want pin the Flutter version of this project with flutterw?',
        ),
      );
      final confirmFlutterwInstall = dcli.confirm(
        'Install flutterw_sidekick_plugin?',
        defaultValue: false,
      );
      if (confirmFlutterwInstall) {
        "${entrypoint.path} sidekick plugins install flutterw_sidekick_plugin"
            .run;
      }
    }

    print(
      'Your sidekick CLI ${dcli.green(cliName)} has been successfully created! 🎉',
    );
  }

  /// Generates a custom sidekick CLI
  ///
  /// Required parameters:
  ///   [projectRoot] - parent of the .git directory
  ///   [packageDir] - directory in which the sidekick cli package will be created
  ///   [entrypointDir] - directory in which entrypoint.sh will be created
  ///
  /// Optional parameters:
  ///   [mainProject] - primary project directory (usually an app which depends on all other packages)
  ///   [packages] - list of all packages in the [projectRoot]
  Future<void> createSidekickPackage({
    required String cliName,
    required Directory projectRoot,
    required Directory packageDir,
    required Directory entrypointDir,
    DartPackage? mainProject,
    List<DartPackage> packages = const [],
  }) async {
    final Directory cliPackage = packageDir.directory('${cliName}_sidekick');

    final entrypoint = entrypointDir.file(cliName.snakeCase);
    final props = SidekickTemplateProperties(
      name: cliName,
      mainProjectPath: mainProject != null
          ? relative(mainProject.root.path, from: projectRoot.absolute.path)
          : null,
      shouldSetFlutterSdkPath: Repository(root: projectRoot)
          .findAllPackages()
          .any((package) => package.isFlutterPackage),
      entrypointLocation: entrypoint,
      packageLocation: cliPackage,
      sidekickCliVersion: core.version,
    );
    SidekickTemplate().generate(props);

    // Download the bundled dart runtime for the CLI
    final bundledDart = (SidekickDartRuntime(cliPackage)..download()).dart;

    // make sure sidekick_core is up-to-date
    final errorCapture = Progress.capture();
    try {
      bundledDart(
        ['pub', 'upgrade', 'sidekick_core'],
        workingDirectory: cliPackage,
        progress: errorCapture,
      );
    } catch (e) {
      // print only in case of error
      printerr(red(errorCapture.lines.join('\n')));
      rethrow;
    }

    bundledDart(
      ['format', cliPackage.path],
      progress: dcli.Progress.printStdErr(),
    );
  }
}
