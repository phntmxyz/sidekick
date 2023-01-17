import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/dart_package.dart' as dart_package;

/// Finds the root of the repo
///
/// Deprecated because sidekick doesn't require a git repo anymore. This method
/// will work most of the time, but git is not a requirement anymore. Thus,
/// people will use sidekick CLIs outside of a git repository
@Deprecated('Use SidekickContext.projectRoot')
Repository findRepository() {
  bool isGitDir(Directory dir) => dir.directory('.git').existsSync();

  final projectRoot = SidekickContext.entryPoint.parent;
  final gitRoot = projectRoot.findParent(isGitDir);
  if (gitRoot == null) {
    throw 'Could not find the root of the repository from ${projectRoot.path}';
  }
  return Repository(root: gitRoot);
}

/// The Git repository of the project
///
/// Might contain a single dart project or multiple packages, or even non dart packages
///
/// Deprecated because sidekick doesn't require a git repo anymore. This method
/// will work most of the time, but git is not a requirement anymore. Thus,
/// people will use sidekick CLIs outside of a git repository
@Deprecated('Use SidekickContext.projectRoot')
class Repository {
  @Deprecated('Use SidekickContext.projectRoot')
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
  @Deprecated('Use SidekickContext.sidekickPackage.root')
  static Directory? get cliPackageDir => SidekickContext.sidekickPackage.root;

  /// The location of the sidekick package
  ///
  /// Throws when not executed with [entryPoint]
  @Deprecated('Use SidekickContext.sidekickPackage.root')
  static Directory get requiredCliPackage =>
      SidekickContext.sidekickPackage.root;

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
  @Deprecated('Use findAllPackages(SidekickContext.projectRoot)')
  List<DartPackage> findAllPackages() => dart_package.findAllPackages(root);
}
