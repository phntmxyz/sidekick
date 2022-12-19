library sidekick_core;

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dartx/dartx_io.dart';
import 'package:dcli/dcli.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:sidekick_core/src/commands/update_command.dart';
import 'package:sidekick_core/src/dart_package.dart';
import 'package:sidekick_core/src/repository.dart';
import 'package:sidekick_core/src/version_checker.dart';

export 'dart:io' hide sleep;

export 'package:args/command_runner.dart';
export 'package:dartx/dartx.dart';
export 'package:dartx/dartx_io.dart';
export 'package:dcli/dcli.dart' hide run, start, startFromArgs, absolute;
export 'package:pub_semver/pub_semver.dart' show Version;
export 'package:sidekick_core/src/cli_util.dart';
export 'package:sidekick_core/src/commands/analyze_command.dart';
export 'package:sidekick_core/src/commands/dart_command.dart';
export 'package:sidekick_core/src/commands/deps_command.dart';
export 'package:sidekick_core/src/commands/flutter_command.dart';
export 'package:sidekick_core/src/commands/install_global_command.dart';
export 'package:sidekick_core/src/commands/plugins/plugins_command.dart';
export 'package:sidekick_core/src/commands/recompile_command.dart';
export 'package:sidekick_core/src/commands/sidekick_command.dart';
export 'package:sidekick_core/src/dart.dart';
export 'package:sidekick_core/src/dart_package.dart';
export 'package:sidekick_core/src/dart_runtime.dart';
export 'package:sidekick_core/src/file_util.dart';
export 'package:sidekick_core/src/flutter.dart';
export 'package:sidekick_core/src/flutterw.dart';
export 'package:sidekick_core/src/forward_command.dart';
export 'package:sidekick_core/src/git.dart';
export 'package:sidekick_core/src/repository.dart';
export 'package:sidekick_core/src/sidekick_package.dart';
export 'package:sidekick_core/src/template/sidekick_package.template.dart';

/// The version of package:sidekick_core
///
/// This is used by the update command to determine if your sidekick cli
/// requires an update
// DO NOT MANUALLY EDIT THIS VERSION, instead run `sk bump-version sidekick_core`
final Version version = Version.parse('0.13.1');

/// Initializes sidekick, call this at the very start of your CLI program
///
/// Set [name] to the name of your CLI entrypoint
///
/// [mainProjectPath] should be set when you have a package that you
/// consider the main package of the whole repository.
/// When your repository contains only one Flutter package in root set
/// `mainProjectPath = '.'`.
/// In a multi package repository you might use the same when the main package
/// is in root, or `mainProjectPath = 'packages/my_app'` when it is in a subfolder.
///
/// Set [flutterSdkPath] when you bind a flutter sdk to this project. This SDK
/// enables the [flutter] and [dart] commands.
/// [dartSdkPath] is inherited from [flutterSdkPath]. Set it only for pure dart
/// projects.
/// The paths can either be absolute or relative to the project root. (E.g. if
/// the custom sidekick CLI is at /Users/foo/project-x/packages/custom_sidekick,
/// relative paths are resolved relative to /Users/foo/project-x)
SidekickCommandRunner initializeSidekick({
  required String name,
  String? description,
  String? mainProjectPath,
  String? flutterSdkPath,
  String? dartSdkPath,
}) {
  DartPackage? mainProject;

  final repo = findRepository();
  if (mainProjectPath != null) {
    mainProject =
        DartPackage.fromDirectory(repo.root.directory(mainProjectPath));
  }

  if (flutterSdkPath != null && dartSdkPath != null) {
    printerr("It's unnecessary to set both `flutterSdkPath` and `dartSdkPath`, "
        "because `dartSdkPath` is inherited from `flutterSdkPath. "
        "Set `dartSdkPath` only for pure dart projects.");
  }

  final runner = SidekickCommandRunner._(
    cliName: name,
    description: description ??
        'A sidekick CLI to equip Dart/Flutter projects with custom tasks',
    repository: repo,
    mainProject: mainProject,
    workingDirectory: Directory.current,
    flutterSdk: _resolveSdkPath(flutterSdkPath, repo.root),
    dartSdk: _resolveSdkPath(dartSdkPath, repo.root),
  );
  return runner;
}

/// A CommandRunner that mounts the sidekick globals
/// [entryWorkingDirectory], [cliName], [repository], [mainProject].
class SidekickCommandRunner<T> extends CommandRunner<T> {
  SidekickCommandRunner._({
    required String cliName,
    required String description,
    required this.repository,
    this.mainProject,
    required this.workingDirectory,
    this.flutterSdk,
    this.dartSdk,
  }) : super(cliName, description) {
    argParser.addFlag(
      'version',
      negatable: false,
      help: 'Print the sidekick version of this CLI.',
    );
  }

  final Repository repository;
  final DartPackage? mainProject;
  final Directory workingDirectory;
  final Directory? flutterSdk;
  final Directory? dartSdk;

  VersionChecker get _versionChecker =>
      injectedVersionChecker ??
      VersionChecker(Repository.requiredSidekickPackage);

  @visibleForTesting
  VersionChecker? injectedVersionChecker;

  /// Mounts the sidekick related globals, returns a function to unmount them
  /// and restore the previous globals
  Unmount mount() {
    final SidekickCommandRunner? oldRunner = _activeRunner;
    _activeRunner = this;
    _entryWorkingDirectory = workingDirectory;

    return () {
      _activeRunner = oldRunner;
      _entryWorkingDirectory = _activeRunner?.workingDirectory;
    };
  }

  @override
  Future<T?> run(Iterable<String> args) async {
    // a new command gets executes, reset whatever exitCode the previous command has set
    exitCode = 0;

    final unmount = mount();

    ArgResults? parsedArgs;
    try {
      parsedArgs = parse(args);
      if (parsedArgs['version'] == true) {
        print('$cliName is using sidekick version $version');
        return null;
      }

      final result = await super.runCommand(parsedArgs);
      return result;
    } finally {
      if (_isUpdateCheckEnabled && !_isSidekickCliUpdateCommand(parsedArgs)) {
        // print warning if the user didn't fully update their CLI
        _checkCliVersionIntegrity();
        // print warning if CLI update is available
        // TODO start the update check in the background at command start
        // TODO prevent multiple update checks when a command start another command
        await _checkForUpdates();
      }
      unmount();
    }
  }

  /// Print a warning if the CLI isn't up to date
  Future<void> _checkForUpdates() async {
    try {
      final updateFuture = _versionChecker.isUpToDate(
        dependency: 'sidekick_core',
        pubspecKeys: ['sidekick', 'cli_version'],
      );
      // If it takes too long, don't wait for it
      final isUpToDate = await updateFuture.timeout(const Duration(seconds: 3));
      if (!isUpToDate) {
        printerr(
          '${yellow('Update available!')}\n'
          'Run ${cyan('$cliName sidekick update')} to update your CLI.',
        );
      }
    } catch (_) {
      /* ignore */
    }
  }

  /// Print a warning if the user manually updated the sidekick_core
  /// minimum version of their CLI and that version doesn't match with the
  /// CLI version listed in the pubspec at the path ['sidekick', 'cli_version']
  void _checkCliVersionIntegrity() {
    final sidekickCoreVersion = _versionChecker
        .getMinimumVersionConstraint(['dependencies', 'sidekick_core']);
    final sidekickCliVersion = _versionChecker
        .getMinimumVersionConstraint(['sidekick', 'cli_version']);

    // old CLI which has no version information yet
    // _checkForUpdates will print a warning to update the CLI in this case
    if (sidekickCliVersion == Version.none) {
      return;
    }

    if (sidekickCliVersion != sidekickCoreVersion) {
      printerr(
        'The sidekick_core version is incompatible with the bash scripts '
        'in /tool and entrypoint because you probably updated the '
        'sidekick_core dependency of your CLI package manually.\n'
        'Please run ${cyan('$cliName sidekick update')} to repair your CLI.',
      );
    }
  }

  /// Returns true if the command executed from [parsedArgs] is [UpdateCommand]
  ///
  /// Copied and adapted from CommandRunner.runCommand
  bool _isSidekickCliUpdateCommand(ArgResults? parsedArgs) {
    if (parsedArgs == null) {
      return false;
    }
    var argResults = parsedArgs;
    Command? command;
    var commands = Map.of(this.commands);

    while (commands.isNotEmpty) {
      if (argResults.command == null) {
        return false;
      }

      // Step into the command.
      argResults = argResults.command!;
      command = commands[argResults.name];
      commands = Map.from(command!.subcommands);
    }

    if (parsedArgs['help'] as bool) {
      // execute HelpCommand from args library
      return false;
    }

    return command is UpdateCommand;
  }
}

/// Enables the [SidekickCommandRunner] to check for `sidekick` updates
bool get _isUpdateCheckEnabled => env['SIDEKICK_ENABLE_UPDATE_CHECK'] == 'true';

typedef Unmount = void Function();

@Deprecated('noop')
void deinitializeSidekick() {}

/// The runner that is currently executing, used for nesting
SidekickCommandRunner? _activeRunner;

/// The working directory (cwd) from which the cli was started
Directory get entryWorkingDirectory =>
    _entryWorkingDirectory ?? Directory.current;
Directory? _entryWorkingDirectory;

/// Name of the cli program
///
/// Usually a short acronym, like 3 characters
String get cliName {
  if (_activeRunner == null) {
    throw OutOfCommandRunnerScopeException('cliName');
  }
  return _activeRunner!.executableName;
}

/// Name of the cli program (if running a generated sidekick CLI)
/// or null (if running the global sidekick CLI)
String? get cliNameOrNull => _activeRunner?.executableName;

/// The root of the repository which contains all projects
Repository get repository {
  if (_activeRunner == null) {
    throw OutOfCommandRunnerScopeException('repository');
  }
  return _activeRunner!.repository;
}

/// The main package which should be executed by default
///
/// The mainProjectPath has to be set by the user in [initializeSidekick].
/// It's optional, not every project has a mainProject, there are repositories
/// with zero or multiple projects.
DartPackage? get mainProject {
  if (_activeRunner == null) {
    throw OutOfCommandRunnerScopeException('mainProject');
  }
  return _activeRunner?.mainProject;
}

/// Returns the path to he Flutter SDK sidekick should use for the [flutter] command
///
/// This variable is usually set to a pinned version of the Flutter SDK per project, i.e.
/// - https://github.com/passsy/flutter_wrapper
/// - https://github.com/fluttertools/fvm
Directory? get flutterSdk {
  if (_activeRunner == null) {
    throw OutOfCommandRunnerScopeException('flutterSdk');
  }
  return _activeRunner?.flutterSdk;
}

/// Returns the path to the Dart SDK sidekick should use for the [dart] command
///
/// Usually inherited from [flutterSdk] which ships with an embedded Dart SDK
Directory? get dartSdk {
  if (_activeRunner == null) {
    throw OutOfCommandRunnerScopeException('dartSdk');
  }
  return _activeRunner?.dartSdk;
}

/// The Dart or Flutter SDK path is set in [initializeSidekick],
/// but the directory doesn't exist
class SdkNotFoundException implements Exception {
  SdkNotFoundException(this.sdkPath, this.repoRoot);

  final String sdkPath;
  final Directory repoRoot;

  late final String message =
      "Dart or Flutter SDK set to '$sdkPath', but that directory doesn't exist. "
      "Please fix the path in `initializeSidekick` (dartSdkPath/flutterSdkPath). "
      "Note that relative sdk paths are resolved relative to the project root, "
      "which in this case is '${repoRoot.path}'.";

  @override
  String toString() {
    return "SdkNotFoundException{message: $message}";
  }
}

/// Transforms [sdkPath] to an absolute directory
///
/// This is to make passing `flutterSdkPath`/`dartSdkPath`
/// in `initializeSidekick` a relative path work from anywhere.
///
/// If [sdkPath] is a relative path, it is resolved relative to
/// the project root [repoRoot].
///
/// Throws a [SdkNotFoundException] if [sdkPath] is given but no
/// existing directory can be found.
Directory? _resolveSdkPath(String? sdkPath, Directory repoRoot) {
  if (sdkPath == null) {
    return null;
  }

  final resolvedDir = (Directory(sdkPath).isAbsolute
          ? Directory(sdkPath)
          // resolve relative path relative to project root
          : repoRoot.directory(sdkPath))
      .absolute;

  if (!resolvedDir.existsSync()) {
    throw SdkNotFoundException(sdkPath, repoRoot);
  }

  return resolvedDir;
}

/// Called when properties of [SidekickCommandRunner] are accessed outside of
/// the execution of a command
class OutOfCommandRunnerScopeException implements Exception {
  String get message => "Can't access SidekickCommandRunner.$property "
      "when no command is executed.";

  final String property;

  OutOfCommandRunnerScopeException(this.property);

  @override
  String toString() {
    return "OutOfCommandRunnerScopeException{message: $message}";
  }
}
