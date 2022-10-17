import 'package:sidekick_core/sidekick_core.dart';

/// Runs pub get on [package]
void pubGet(DartPackage package) {
  sidekickDartRuntime.dart(
    ['pub', 'get'],
    workingDirectory: package.root,
    progress: Progress.printStdErr(),
  );
}
