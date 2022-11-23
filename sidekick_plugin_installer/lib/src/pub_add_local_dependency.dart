import 'package:sidekick_core/sidekick_core.dart';

/// This function is deprecated. Use [addDependency] instead
///
/// Adds dependency from a local [path] to [package]
@Deprecated('Use `addDependency` instead.')
void pubAddLocalDependency(
  DartPackage package,
  String path,
) {
  final name = DartPackage.fromDirectory(Directory(path))!.name;

  sidekickDartRuntime.dart(
    ['pub', 'remove', name],
    workingDirectory: package.root,
    progress: Progress.devNull(),
  );

  sidekickDartRuntime.dart(
    ['pub', 'add', name, '--path', path],
    workingDirectory: package.root,
    progress: Progress.printStdErr(),
  );
}
