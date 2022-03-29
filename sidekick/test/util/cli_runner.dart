import 'dart:io';

import 'package:sidekick_core/sidekick_core.dart';
import 'package:test_process/test_process.dart';

/// Executes the CLI in a separate process so it doesn't interfere with
/// singletons in the test like the [entryWorkingDirectory]
Future<TestProcess> sidekickCli(
  List<String> args, {
  required Directory workingDirectory,
}) async {
  // Use this to debug the sidekick CLI
  // import 'package:sidekick/sidekick.dart' as sidekick;
  // await IOOverrides.runZoned(
  //   () => sidekick.main(args),
  //   getCurrentDirectory: () => workingDirectory,
  // );

  return TestProcess.start(
    'dart',
    ['${Directory.current.path}/bin/sidekick.dart', ...args],
    workingDirectory: workingDirectory.path,
    forwardStdio: true,
  );
}
