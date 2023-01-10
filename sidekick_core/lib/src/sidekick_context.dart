import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/sidekick_package.dart';

class SidekickContext {
  SidekickContext._();

  /// The location of the sidekick package
  static Directory get sidekickPackageDir => sidekickPackage.root;

  /// The sidekick package inside the repository
  static SidekickPackage get sidekickPackage {
    final injectedPackageHome = env['SIDEKICK_PACKAGE_HOME'];
    if (injectedPackageHome != null && injectedPackageHome.isNotBlank) {
      return SidekickPackage.fromDirectory(Directory(injectedPackageHome))!;
    }

    // - when CLI is run with `dart bin/main.dart`: /Users/pepe/repos/sidekick/sk_sidekick/bin/main.dart
    // - when CLI is run with compiled entrypoint: /Users/pepe/repos/sidekick/sk_sidekick/build/cli.exe
    // - in `UpdateCommand` when the latest `update_sidekick_cli.dart` written to build/update.dart to be executed
    final script = File(DartScript.self.pathToScript);
    if (['bin/main.dart', 'build/cli.exe', 'build/update.dart']
        .contains(script.uri.pathSegments.takeLast(2).join('/'))) {
      return SidekickPackage.fromDirectory(script.parent.parent)!;
    }

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
    if (_calledViaEntrypoint) {
      final injectedEntryPointPath = env['SIDEKICK_ENTRYPOINT_HOME'];
      if (injectedEntryPointPath == null || injectedEntryPointPath.isBlank) {
        throw 'Injected entrypoint was not set (env.SIDEKICK_ENTRYPOINT_HOME)';
      }
      final entrypoint = File(normalize('$injectedEntryPointPath/$cliName'));
      if (!entrypoint.existsSync()) {
        throw 'Injected entrypoint does not exist ${entrypoint.absolute.path}';
      }
      return entrypoint;
    } else {
      Directory current = sidekickPackageDir;
      final entrypointName = '${cliNameOrNull ?? sidekickPackage.cliName}.sh';
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
          '${entryWorkingDirectory.absolute.path} and '
          '${sidekickPackageDir.absolute.path}';
    }

    return gitRoot;
  }

  /// Whether the sidekick CLI is currently running through the shell entrypoint
  ///
  /// User's run their sidekick CLIs by executing their shell entrypoint,
  /// [_calledViaEntrypoint] is true in that case
  ///
  /// For debugging purposes one may want to run the CLI not through the
  /// compiled entrypoint but through `dart bin/main.dart`,
  /// [_calledViaEntrypoint] is false in that case
  static final _calledViaEntrypoint = env.exists('SIDEKICK_PACKAGE_HOME');
}
