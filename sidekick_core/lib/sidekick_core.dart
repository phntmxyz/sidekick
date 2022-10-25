library sidekick_core;

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dartx/dartx_io.dart';
import 'package:dcli/dcli.dart';
import 'package:sidekick_core/src/dart_package.dart';
import 'package:sidekick_core/src/repository.dart';

export 'dart:io' hide sleep;

export 'package:args/command_runner.dart';
export 'package:dartx/dartx.dart';
export 'package:dartx/dartx_io.dart';
export 'package:dcli/dcli.dart' hide run, start, startFromArgs, absolute;
export 'package:sidekick_core/src/cli_util.dart';
export 'package:sidekick_core/src/commands/analyze_command.dart';
export 'package:sidekick_core/src/commands/dart_command.dart';
export 'package:sidekick_core/src/commands/deps_command.dart';
export 'package:sidekick_core/src/commands/flutter_command.dart';
export 'package:sidekick_core/src/commands/install_global_command.dart';
export 'package:sidekick_core/src/commands/plugins/plugins_command.dart';
export 'package:sidekick_core/src/commands/recompile_command.dart';
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
/// relative paths are resolved relative from /Users/foo/project-x)
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
  }) : super(cliName, description);

  final Repository repository;
  final DartPackage? mainProject;
  final Directory workingDirectory;
  final Directory? flutterSdk;
  final Directory? dartSdk;

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
    try {
      final result = await super.run(args);
      return result;
    } finally {
      unmount();
    }
  }
}

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
    throw 'You cannot access cliName '
        'outside of a Command executed with SidekickCommandRunner.';
  }
  return _activeRunner!.executableName;
}

/// Name of the cli program (if running a generated sidekick CLI)
/// or null (if running the global sidekick CLI)
String? get cliNameOrNull => _activeRunner?.executableName;

/// The root of the repository which contains all projects
Repository get repository {
  if (_activeRunner == null) {
    throw 'You cannot access repository '
        'outside of a Command executed with SidekickCommandRunner.';
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
    throw 'You cannot access mainProject '
        'outside of a Command executed with SidekickCommandRunner.';
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
    throw 'You cannot access flutterSdk '
        'outside of a Command executed with SidekickCommandRunner.';
  }
  return _activeRunner?.flutterSdk;
}

/// Returns the path to the Dart SDK sidekick should use for the [dart] command
///
/// Usually inherited from [flutterSdk] which ships with an embedded Dart SDK
Directory? get dartSdk {
  if (_activeRunner == null) {
    throw 'You cannot access dartSdk '
        'outside of a Command executed with SidekickCommandRunner.';
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
/// If [sdkPath] is a relative path, it is resolved relative from
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
          // resolve relative path relative from project root
          : repoRoot.directory(sdkPath))
      .absolute;

  if (!resolvedDir.existsSync()) {
    throw SdkNotFoundException(sdkPath, repoRoot);
  }

  return resolvedDir;
}
