import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/sidekick_core.dart' as core;
import 'package:sidekick_core/src/sidekick_package.dart';

/// Environment variable containing the location of the shell `entrypoint`, when
/// executing the sidekick CLI with the shell entrypoint
///
/// May be not set when debugging where the CLI is executed directly on the
/// DartVM by calling `dart bin/main.dart` without the entrypoint
const String _envEntrypointHome = 'SIDEKICK_ENTRYPOINT_HOME';

/// Environment variable containing the location of the dart package of this
/// sidekick CLI. It contains the source code and tool scripts of this sidekick
/// CLI.
const String _envPackageHome = 'SIDEKICK_PACKAGE_HOME';

class SidekickContext {
  SidekickContext._();

  // TODO add context cache that SidekickRunner can inject while executing a
  //  Command to prevent multiple (expensive) lookups
  // SidekickContextCache cache;

  /// Returns the name of the CLI
  static String get cliName => throw 'TODO';

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

  /// The location of the sidekick package
  static Directory get sidekickPackageDir => sidekickPackage.root;

  /// The main package/app which should be executed by the [flutter] command
  ///
  /// The mainProjectPath can be set in [initializeSidekick].
  ///
  /// It's optional, not every project has a mainProject, there are repositories
  /// with zero or multiple projects.
  static DartPackage? get mainProject => throw 'TODO';

  /// The sidekick package inside the repository
  static SidekickPackage get sidekickPackage {
    final injectedPackageHome = env[_envPackageHome];
    if (injectedPackageHome != null && injectedPackageHome.isNotBlank) {
      return SidekickPackage.fromDirectory(Directory(injectedPackageHome))!;
    }

    final script = File(DartScript.self.pathToScript);
    final scriptPath = script.uri.path;

    // When CLI is run with compiled entrypoint: /Users/pepe/repos/sidekick/sk_sidekick/build/cli.exe
    if (scriptPath.endsWith('build/cli.exe')) {
      return SidekickPackage.fromDirectory(script.parent.parent)!;
    }

    // When CLI is run with `dart bin/main.dart`: /Users/pepe/repos/sidekick/sk_sidekick/bin/main.dart
    if (scriptPath.endsWith('/bin/main.dart')) {
      return SidekickPackage.fromDirectory(script.parent.parent)!;
    }

    // in `UpdateCommand` when the latest `update_sidekick_cli.dart` written to build/update.dart to be executed
    if (scriptPath.endsWith('/build/update.dart')) {
      return SidekickPackage.fromDirectory(script.parent.parent)!;
    }

    // Fallback strategy: searching all parent folders until we find a dart package root
    final scriptDirectory = script.parent;
    Directory current = Directory(scriptDirectory.path);

    while (true) {
      final sidekickPackage = SidekickPackage.fromDirectory(current);
      if (sidekickPackage != null) {
        return sidekickPackage;
      }

      final parent = current.parent;
      if (parent.path == current.path) {
        throw "Can't find sidekickPackage from ${scriptDirectory.path}";
      }
      current = parent;
    }
  }

  /// The location of the entrypoint
  ///
  /// Usually injected from the entrypoint itself via `env.SIDEKICK_ENTRYPOINT_HOME`
  static File get entryPoint {
    if (env.exists(_envEntrypointHome)) {
      // CLI is called via entrypoint
      final injectedEntryPointPath = env[_envEntrypointHome];
      if (injectedEntryPointPath == null || injectedEntryPointPath.isBlank) {
        throw 'Injected entrypoint was not set (env.$_envEntrypointHome)';
      }
      final entrypoint =
          File(normalize('$injectedEntryPointPath/${core.cliName}'));
      if (!entrypoint.existsSync()) {
        throw 'Injected entrypoint does not exist ${entrypoint.absolute.path}';
      }
      return entrypoint;
    } else {
      // Fallback strategy: Search all parents directories for the entrypoint
      // This case is used when debugging the cli and the dart program is
      // started on the DartVM, and not called and compiled with the entrypoint
      final entrypointName = core.cliNameOrNull ?? sidekickPackage.cliName;

      Directory current = sidekickPackageDir;
      while (true) {
        final entrypoint = current
            .listSync()
            .whereType<File>()
            .where((it) => it.name == entrypointName);
        if (entrypoint.isNotEmpty) {
          return entrypoint.single;
        }

        final parent = current.parent;
        if (parent.path == current.path) {
          throw "Can't find entrypoint $entrypointName from ${sidekickPackageDir.path}";
        }
        current = parent;
      }
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
