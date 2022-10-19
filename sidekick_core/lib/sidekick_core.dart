library sidekick_core;

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dartx/dartx_io.dart';
import 'package:sidekick_core/src/cli_util.dart';
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
export 'package:sidekick_core/src/commands/flutter_command.dart';
export 'package:sidekick_core/src/commands/install_global_command.dart';
export 'package:sidekick_core/src/commands/plugins/plugins_command.dart';
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

  final runner = SidekickCommandRunner._(
    cliName: name,
    description: description ??
        'A sidekick CLI to equip Dart/Flutter projects with custom tasks',
    repository: repo,
    mainProject: mainProject,
    workingDirectory: Directory.current,
    flutterSdk: flutterSdkPath == null ? null : Directory(flutterSdkPath),
    dartSdk: dartSdkPath == null ? null : Directory(dartSdkPath),
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
    final result = await super.run(args);
    unmount();
    return result;
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
    error(
      'You cannot access cliName '
      'outside of a Command executed with SidekickCommandRunner.',
    );
  }
  return _activeRunner!.executableName;
}

/// The root of the repository which contains all projects
Repository get repository {
  if (_activeRunner == null) {
    error(
      'You cannot access repository '
      'outside of a Command executed with SidekickCommandRunner.',
    );
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
    error(
      'You cannot access mainProject '
      'outside of a Command executed with SidekickCommandRunner.',
    );
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
    error(
      'You cannot access flutterSdk '
      'outside of a Command executed with SidekickCommandRunner.',
    );
  }
  return _activeRunner?.flutterSdk;
}

/// Returns the path to the Dart SDK sidekick should use for the [dart] command
///
/// Usually inherited from [flutterSdk] which ships with an embedded Dart SDK
Directory? get dartSdk {
  if (_activeRunner == null) {
    error(
      'You cannot access dartSdk '
      'outside of a Command executed with SidekickCommandRunner.',
    );
  }
  return _activeRunner?.dartSdk ??
      _activeRunner?.flutterSdk?.directory('bin/cache/dart-sdk');
}
