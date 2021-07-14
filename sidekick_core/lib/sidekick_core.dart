library sidekick_core;

import 'dart:io';

import 'package:dartx/dartx_io.dart';
import 'package:sidekick_core/src/cli_util.dart';
import 'package:sidekick_core/src/dart_package.dart';
import 'package:sidekick_core/src/repository.dart';

export 'dart:io' hide sleep;

export 'package:dartx/dartx.dart';
export 'package:dartx/dartx_io.dart';
export 'package:dcli/dcli.dart' hide run, start, startFromArgs, absolute;
export 'package:sidekick_core/src/cli_util.dart';
export 'package:sidekick_core/src/commands/analyze_command.dart';
export 'package:sidekick_core/src/commands/dart_command.dart';
export 'package:sidekick_core/src/commands/flutter_command.dart';
export 'package:sidekick_core/src/dart.dart';
export 'package:sidekick_core/src/dart_package.dart';
export 'package:sidekick_core/src/file_util.dart';
export 'package:sidekick_core/src/flutterw.dart';
export 'package:sidekick_core/src/forward_command.dart';
export 'package:sidekick_core/src/git.dart';
export 'package:sidekick_core/src/repository.dart';

/// The working directory (cwd) from which the cli was started
final Directory entryWorkingDirectory = Directory.current;

/// Initializes sidekick, call this at the very start of your CLI program
void initializeSidekick({
  required String name,
  String? mainProjectPath,
}) {
  _cliName = name;
  _repository = findRepository();
  if (mainProjectPath != null) {
    _mainProject = DartPackage.fromDirectory(repository.root.directory(mainProjectPath));
  }
}

/// Name of the cli program
///
/// Usually a short acronym, like 3 characters
String get cliName {
  if (_cliName == null) {
    error('cliName not initialized, call initializeSidekick() first');
  }
  return _cliName!;
}

String? _cliName;

/// The root of the repository which contains all projects
Repository get repository {
  if (_repository == null) {
    error('repository not initialized, call initializeSidekick() first');
  }
  return _repository!;
}

Repository? _repository;

/// The main package which should be executed by default
///
/// This has to be set by the
DartPackage get mainProject {
  if (_mainProject == null) {
    error('mainProject is not initialized. Set mainProjectPath when calling initializeSidekick();');
  }
  return _mainProject!;
}

DartPackage? _mainProject;
