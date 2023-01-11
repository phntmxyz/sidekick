import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/sidekick_core.dart' as core;
import 'package:sidekick_core/src/sidekick_package.dart';

/// Environment variable containing the location of the shell `entryPoint`, when
/// executing the sidekick CLI with the shell entrypoint
///
/// May be not set when debugging where the CLI is executed directly on the
/// DartVM by calling `dart bin/main.dart` without the entrypoint
const String _envEntryPointHome = 'SIDEKICK_ENTRYPOINT_HOME';

/// Environment variable containing the location of the dart package of this
/// sidekick CLI. It contains the source code and tool scripts of this sidekick
/// CLI.
///
/// SIDEKICK_PACKAGE_HOME is set by the `tool/run.sh` script and always called
/// when executed via `entryPoint`
const String _envPackageHome = 'SIDEKICK_PACKAGE_HOME';

class SidekickContext {
  SidekickContext._();

  // TODO add context cache that SidekickRunner can inject while executing a
  //  Command to prevent multiple (expensive) lookups
  // SidekickContextCache cache;

  /// Returns the name of the CLI
  static String get cliName {
    return sidekickPackage.cliName;
  }

  /// Returns the directory of the Flutter SDK sidekick uses for the [flutter] command
  ///
  /// This variable is usually set to a pinned version of the Flutter SDK per project, i.e.
  /// - https://github.com/passsy/flutter_wrapper
  /// - https://github.com/fluttertools/fvm
  ///
  /// The flutterSdkPath can be set in [initializeSidekick].
  static Directory? get flutterSdk => throw 'TODO';

  /// Returns the directory of the Dart SDK sidekick uses for the [dart] command
  ///
  /// Overrides the Dart SDK of [flutterSdk] when set
  ///
  /// The dartSdkPath can be set in [initializeSidekick].
  static Directory? get dartSdk => throw 'TODO';

  /// The main package/app which should be executed by the [flutter] command
  ///
  /// The mainProjectPath can be set in [initializeSidekick].
  ///
  /// It's optional, not every project has a mainProject, there are repositories
  /// with zero or multiple projects.
  static DartPackage? get mainProject => throw 'TODO';

  /// The location of the sidekick package inside the [repository]
  static Directory get sidekickPackageDir => sidekickPackage.root;

  /// The sidekick package inside the [repository]
  static SidekickPackage get sidekickPackage {
    final injectedPackageHome = env[_envPackageHome];
    if (injectedPackageHome != null && injectedPackageHome.isNotBlank) {
      // When called via entryPoint, immediately return the package
      return SidekickPackage.fromDirectory(Directory(injectedPackageHome))!;
    }

    final script = File(DartScript.self.pathToScript);
    final scriptPath = script.uri.path;
    final pathSep = Platform.pathSeparator;

    // When CLI is run with compiled entryPoint: <sidekick package>/build/cli.exe
    if (scriptPath.endsWith('${pathSep}build${pathSep}cli.exe')) {
      return SidekickPackage.fromDirectory(script.parent.parent)!;
    }

    // When CLI is run with `dart bin/main.dart`: <sidekick package>/bin/main.dart
    if (scriptPath.endsWith('${pathSep}bin${pathSep}main.dart')) {
      return SidekickPackage.fromDirectory(script.parent.parent)!;
    }

    // in `UpdateCommand` when the latest `update_sidekick_cli.dart` is written to <sidekick package>/build/update.dart to be executed
    if (scriptPath.endsWith('${pathSep}bin${pathSep}update.dart')) {
      return SidekickPackage.fromDirectory(script.parent.parent)!;
    }

    // Fallback strategy: searching all parent folders until we find a dart package root
    final scriptDirectory = script.parent;
    Directory current = Directory(scriptDirectory.path);
    final repoRoot = repository;

    while (current.isWithin(repoRoot)) {
      final sidekickPackage = SidekickPackage.fromDirectory(current);
      if (sidekickPackage != null) {
        return sidekickPackage;
      }

      current = current.parent;
    }
    throw "Can't find sidekickPackage from ${scriptDirectory.path}";
  }

  /// The location of the entryPoint inside the [repository]
  ///
  /// Usually injected from the entryPoint itself via `env.SIDEKICK_ENTRYPOINT_HOME`
  static File get entryPoint {
    if (env.exists(_envEntryPointHome)) {
      // CLI is called via entryPoint
      final injectedEntryPointPath = env[_envEntryPointHome];
      if (injectedEntryPointPath == null || injectedEntryPointPath.isBlank) {
        throw 'Injected entryPoint was not set (env.$_envEntryPointHome)';
      }
      final entryPoint =
          File(normalize('$injectedEntryPointPath/${core.cliName}'));
      if (!entryPoint.existsSync()) {
        throw 'Injected entryPoint does not exist ${entryPoint.absolute.path}';
      }
      return entryPoint;
    } else {
      // Fallback strategy: Search all parents directories for the entrypoint
      // This case is used when debugging the cli and the dart program is
      // started on the DartVM, and not called and compiled with the entrypoint
      final entryPointName = core.cliNameOrNull ?? sidekickPackage.cliName;

      Directory current = sidekickPackageDir;
      final repoRoot = repository;

      while (current.isWithin(repoRoot)) {
        final entryPoint = current
            .listSync()
            .whereType<File>()
            .where((it) => it.name == entryPointName);
        if (entryPoint.isNotEmpty) {
          return entryPoint.single;
        }

        current = current.parent;
      }
      throw "Can't find entryPoint $entryPointName from ${sidekickPackageDir.path}";
    }
  }

  /// The git repository root the [sidekickPackage] is located in
  static Directory get repository {
    bool isGitDir(Directory dir) => dir.directory('.git').existsSync();

    final gitRoot = sidekickPackageDir.findParent(isGitDir);

    if (gitRoot == null) {
      throw 'Could not find the root of the repository. Searched in '
          '${sidekickPackageDir.absolute.path}';
    }

    return gitRoot;
  }
}
