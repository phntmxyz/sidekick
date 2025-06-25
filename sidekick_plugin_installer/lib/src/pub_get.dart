import 'package:sidekick_core/sidekick_core.dart';

/// Runs pub get on [package]
Future<void> pubGet(DartPackage package) async {
  await sidekickDartRuntime.dart(
    ['pub', 'get'],
    workingDirectory: package.root,
    progress: Progress.printStdErr(),
  );
}
