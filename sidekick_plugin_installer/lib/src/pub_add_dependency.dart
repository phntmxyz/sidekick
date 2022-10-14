import 'package:sidekick_core/sidekick_core.dart';

/// Adds the dependency to [package]
void pubAddDependency(
  DartPackage package,
  String dependency, {
  String? version,
}) {
  sidekickDartRuntime.dart(
    ['pub', 'remove', dependency],
    workingDirectory: package.root,
  );

  sidekickDartRuntime.dart(
    ['pub', 'add', dependency, if (version != null) version],
    workingDirectory: package.root,
  );
}
