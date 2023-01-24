import 'package:dcli/dcli.dart' as dcli;
import 'package:recase/recase.dart';
import 'package:sidekick/src/util/dcli_ask_validators.dart';
import 'package:sidekick/src/util/directory_extension.dart';
import 'package:sidekick/src/util/name_suggester.dart';
import 'package:sidekick_core/sidekick_core.dart'
    hide mainProject, repository, cliName, cliNameOrNull, entryWorkingDirectory;
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
          'The directory in which the CLI entrypoint script should be created. '
          'This will be the projectRoot',
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

    // Collection phase:
    // Gather data from user/env/file system (read only)
    final _InitInputs inputs = _collectInformation();

    // Execution phase:
    // Create files and directories, download dependencies, etc.
    print("\n${green("Generating ${inputs.cliName}_sidekick")}");
    await _createSidekickPackage(inputs);
    print("Code generation successful");

    // Post-install phase:
    // optional steps to further improve the CLI
    installFlutterWrapper(inputs);

    print(
      'Your sidekick CLI ${dcli.green(inputs.cliName)} has been successfully created! 🎉',
    );
  }

  /// Collects all information needed to create a sidekick CLI
  ///
  /// Does only file system reads, no writes
  _InitInputs _collectInformation() {
    final projectRoot = Directory(
      argResults!['entrypointDirectory'] as String? ??
          argResults!.rest.firstOrNull ??
          () {
            print(
              '${green('Enter the directory in which the entrypoint script should be created.')}\n'
              'Or press enter to use the current directory.',
            );
            final answer = dcli.ask(
              'Set entryPoint directory:',
              validator: const DirectoryExistsValidator(),
              defaultValue: Directory.current.path,
            );
            print('');
            return answer;
          }(),
    ).canonicalized;
    if (!projectRoot.existsSync()) {
      print(
        'Info: projectRoot directory containing the entryPoint does not exist yet. '
        'It will be created at ${projectRoot.path}\n'
        "Info: Please double check your entryPoint directory, "
        "you're about to create a sidekick CLI in an empty directory.",
      );
    }

    final packageDir = Directory(
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
    if (!packageDir.isWithinOrEqual(projectRoot)) {
      throw 'CLI package directory ${packageDir.path} is not within or equal to ${projectRoot.path}';
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

    final List<DartPackage> packages = projectRoot.existsSync()
        ? Repository(root: projectRoot).findAllPackages()
        : [];

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

    return _InitInputs(
      cliName: cliName,
      projectRoot: projectRoot,
      packageDir: packageDir,
      mainProject: mainProject,
      packages: packages,
    );
  }

  /// Generates a custom sidekick CLI in [_InitInputs.projectRoot]
  Future<void> _createSidekickPackage(_InitInputs inputs) async {
    if (!inputs.projectRoot.existsSync()) {
      inputs.projectRoot.createSync(recursive: true);
    }
    final Directory cliPackage =
        inputs.packageDir.directory('${inputs.cliName}_sidekick');

    final entrypoint = inputs.projectRoot.file(inputs.cliName.snakeCase);
    final props = SidekickTemplateProperties(
      name: inputs.cliName,
      mainProjectPath: inputs.mainProject != null
          ? relative(inputs.mainProject!.root.path,
              from: inputs.projectRoot.absolute.path)
          : null,
      shouldSetFlutterSdkPath: Repository(root: inputs.projectRoot)
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

  /// Asks user to install flutterw_sidekick_plugin when a Flutter package is detected
  void installFlutterWrapper(_InitInputs inputs) {
    final entrypoint = inputs.projectRoot.file(inputs.cliName);

    final flutterPackages = [
      if (inputs.mainProject != null) inputs.mainProject!,
      ...inputs.packages
    ].filter((package) => package.isFlutterPackage).toList();

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
        defaultValue:
            env['SIDEKICK_INIT_APPROVE_FLUTTERW_INSTALL'] == 'true' || false,
      );
      if (confirmFlutterwInstall) {
        "${entrypoint.path} sidekick plugins install flutterw_sidekick_plugin"
            .run;
      }
    }
  }
}

/// All information to generate a sidekick CLI
class _InitInputs {
  /// Name of the entryPoint
  final String cliName;

  /// Where the entryPoint is located
  final Directory projectRoot;

  /// directory in which the sidekick cli package will be created
  final Directory packageDir;

  /// primary project directory (usually an app which depends on all other packages)
  final DartPackage? mainProject;

  /// list of all packages in [projectRoot]
  final List<DartPackage> packages;

  const _InitInputs({
    required this.cliName,
    required this.projectRoot,
    required this.packageDir,
    this.mainProject,
    this.packages = const [],
  });
}
