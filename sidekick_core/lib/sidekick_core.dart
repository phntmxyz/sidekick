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
export 'package:sidekick_core/src/commands/plugins_command.dart';
export 'package:sidekick_core/src/dart.dart';
export 'package:sidekick_core/src/dart_package.dart';
export 'package:sidekick_core/src/dart_runtime.dart';
export 'package:sidekick_core/src/file_util.dart';
export 'package:sidekick_core/src/flutterw.dart';
export 'package:sidekick_core/src/forward_command.dart';
export 'package:sidekick_core/src/git.dart';
export 'package:sidekick_core/src/repository.dart';

/// Initializes sidekick, call this at the very start of your CLI program
///
/// Set [name] to the name of your CLI entrypoint
///
/// [mainProjectPath], when set, links to the main package. For a flutter apps
/// it is the package that actually builds the flutter app.
/// Set [mainProjectPath] relative to the git repository root
SidekickCommandRunner initializeSidekick({
  required String name,
  String? description,
  String? mainProjectPath,
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
  }) : super(cliName, description);

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
