import 'dart:io';

import 'package:test_process/test_process.dart';

/// Executes the CLI in a separate process
Future<TestProcess> sidekickCli(
  List<String> args, {
  required Directory workingDirectory,
}) {
  return TestProcess.start(
    'dart',
    ['${Directory.current.path}/bin/sidekick.dart', ...args],
    workingDirectory: workingDirectory.path,
    forwardStdio: true,
  );
}
