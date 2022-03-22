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
export 'package:sidekick_core/src/dart.dart';
export 'package:sidekick_core/src/dart_package.dart';
export 'package:sidekick_core/src/file_util.dart';
export 'package:sidekick_core/src/flutterw.dart';
export 'package:sidekick_core/src/forward_command.dart';
export 'package:sidekick_core/src/git.dart';
export 'package:sidekick_core/src/repository.dart';

/// The working directory (cwd) from which the cli was started
Directory get entryWorkingDirectory =>
    _entryWorkingDirectory ??= Directory.current;
Directory? _entryWorkingDirectory;

/// Initializes sidekick, call this at the very start of your CLI program
///
/// Set [name] to the name of your CLI entrypoint
///
/// [mainProjectPath], when set, links to the main package. For a flutter apps
/// it is the package that actually builds the flutter app. The
/// [mainProjectPath] is relative to the entrypoint, the bash executable for
/// your sidekick CLI.
SidekickCommandRunner initializeSidekick({
  required String name,
  String? description,
  String? mainProjectPath,
}) {
  DartPackage? mainProject;

  final cwd = Directory.current;
  _entryWorkingDirectory = cwd;
  final repo = findRepository();

  if (mainProjectPath != null) {
    mainProject =
        DartPackage.fromDirectory(repo.root.directory(mainProjectPath));
  }

  final runner = SidekickCommandRunner(
    executableName: name,
    description: description ??
        'A sidekick CLI to equip Dart/Flutter projects with custom tasks',
    repository: repo,
    mainProject: mainProject,
    workingDirectory: cwd,
  );
  return runner;
}

/// A CommandRunner that mounts
class SidekickCommandRunner<T> extends CommandRunner<T> {
  SidekickCommandRunner({
    required String executableName,
    required String description,
    required this.repository,
    this.mainProject,
    required this.workingDirectory,
  }) : super(executableName, description);

  final Repository repository;
  final DartPackage? mainProject;
  final Directory workingDirectory;

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
    final unmount = mount();
    final result = await super.run(args);
    unmount();
    return result;
  }
}

typedef Unmount = void Function();

@Deprecated('noop')
void deinitializeSidekick() {}

SidekickCommandRunner? _activeRunner;

/// Name of the cli program
///
/// Usually a short acronym, like 3 characters
String get cliName {
  if (_activeRunner == null) {
    error('cliName not initialized, call initializeSidekick() first');
  }
  return _activeRunner!.executableName;
}

/// The root of the repository which contains all projects
Repository get repository {
  if (_activeRunner == null) {
    error('repository not initialized, call initializeSidekick() first');
  }
  return _activeRunner!.repository;
}

/// The main package which should be executed by default
///
/// This has to be set by the
DartPackage get mainProject {
  final project = _activeRunner?.mainProject;
  if (project == null) {
    error(
      'mainProject is not initialized. Set mainProjectPath when calling initializeSidekick();',
    );
  }
  return project;
}
