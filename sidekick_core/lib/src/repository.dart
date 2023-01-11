import 'dart:io';

import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/sidekick_context.dart';

/// Finds the root of the repo
@Deprecated('Use SidekickContext') // TODO be more precise
Repository findRepository() => Repository(root: SidekickContext.repository);

/// The Git repository of the project
///
/// Might contain a single dart project or multiple packages, or even non dart packages
@Deprecated('Use SidekickContext') // TODO be more precise
class Repository {
  Repository({
    required this.root,
  });

  final Directory root;

  /// The location of the sidekick package
  ///
  /// Usually injected from the tool/run.sh script itself via `env.SIDEKICK_PACKAGE_HOME`
  ///
  /// `null` when not executed with [entryPoint]
  ///
  /// Usually you want to use [sidekickPackage]
  @Deprecated('Use SidekickContext.sidekickPackageDir')
  static Directory? get cliPackageDir => SidekickContext.sidekickPackageDir;

  /// The location of the sidekick package
  ///
  /// Throws when not executed with [entryPoint]
  @Deprecated('Use SidekickContext.sidekickPackageDir')
  static Directory get requiredCliPackage => SidekickContext.sidekickPackageDir;

  /// The sidekick package inside the repository
  ///
  /// `null` when not executed with [entryPoint]
  @Deprecated('Use SidekickContext.sidekickPackage')
  static SidekickPackage? get sidekickPackage =>
      SidekickContext.sidekickPackage;

  /// The sidekick package inside the repository
  ///
  /// Throws when not executed with [entryPoint]
  @Deprecated('Use SidekickContext.sidekickPackage')
  static SidekickPackage get requiredSidekickPackage =>
      SidekickContext.sidekickPackage;

  /// The location of the entrypoint
  ///
  /// Usually injected from the entrypoint itself via `env.SIDEKICK_ENTRYPOINT_HOME`
  @Deprecated('Use SidekickContext.entryPoint')
  static File? get entryPoint => SidekickContext.entryPoint;

  /// The location of the entrypoint
  ///
  /// Throws when not executed with [entryPoint]
  @Deprecated('Use SidekickContext.entryPoint')
  static File get requiredEntryPoint => SidekickContext.entryPoint;

  /// Returns the list of all packages in the repository
  @Deprecated('Use SidekickContext') // TODO be more precise
  List<DartPackage> findAllPackages() {
    return root
        .allSubDirectories((dir) {
          if (dir.name.startsWith('.')) {
            // ignore hidden folders
            return false;
          }
          if (dir.name == 'build') {
            final package = DartPackage.fromDirectory(dir.parent);
            if (package != null) {
              // ignore <dartPackage>/build dir
              return false;
            }
          }
          return true;
        })
        .mapNotNull((it) => DartPackage.fromDirectory(it))
        .toList();
  }
}

extension FindInDirectory on Directory {
  /// Recursively goes up and tries to find a [Directory] matching [predicate]
  ///
  /// Returns `null` when reaching root (/) without a match
  Directory? findParent(bool Function(Directory dir) predicate) {
    var dir = this;
    // ignore: literal_only_boolean_expressions
    while (true) {
      if (predicate(dir)) {
        return dir;
      }
      final parent = dir.parent;
      if (dir.toString() == parent.toString()) {
        // not found
        return null;
      }
      dir = dir.parent;
    }
  }

  Iterable<Directory> allSubDirectories(
    bool Function(Directory dir) predicate,
  ) sync* {
    yield this;
    for (final dir in listSync().whereType<Directory>().where(predicate)) {
      yield* dir.allSubDirectories(predicate);
    }
  }
}
