import 'package:sidekick_core/sidekick_core.dart';

/// This function is deprecated. Use [addDependency] instead
///
/// Adds the dependency to [package]
@Deprecated('Use `addDependency` or `addDependencyFromPluginContext` instead.')
void pubAddDependency(
  DartPackage package,
  String dependency, {
  String? version,
}) {
  sidekickDartRuntime.dart(
    ['pub', 'remove', dependency],
    workingDirectory: package.root,
    progress: Progress.devNull(),
  );

  sidekickDartRuntime.dart(
    ['pub', 'add', dependency, if (version != null) version],
    workingDirectory: package.root,
    progress: Progress.printStdErr(),
  );
}
