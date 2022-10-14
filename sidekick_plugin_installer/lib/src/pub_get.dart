import 'package:sidekick_core/sidekick_core.dart';

void pubGet(DartPackage package) {
  sidekickDartRuntime.dart(
    ['pub', 'get'],
    workingDirectory: package.root,
  );
}
