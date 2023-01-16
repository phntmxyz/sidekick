import 'dart:io';

import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/sidekick_context.dart';
import 'package:sidekick_core/src/dart_package.dart' as dartpackage;

/// Finds the root of the repo
@Deprecated('Use SidekickContext.repository') // TODO be more precise
Repository findRepository() => SidekickContext.repository;

/// The Git repository of the project
///
/// Might contain a single dart project or multiple packages, or even non dart packages
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
  static File? get entryPoint => SidekickContext.entryPoint.file;

  /// The location of the entrypoint
  ///
  /// Throws when not executed with [entryPoint]
  @Deprecated('Use SidekickContext.entryPoint')
  static File get requiredEntryPoint => SidekickContext.entryPoint.file;

  /// Returns the list of all packages in the repository
  List<DartPackage> findAllPackages() => dartpackage.findAllPackages(root);
}
