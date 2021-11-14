import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

import 'templates/templates.dart';

void main() {
  group('project type detection', () {
    test('init for root with packages', () async {
      final project = setupTemplateProject('test/templates/root_with_packages');
      final process =
          await sidekickCli(['init', '-n', 'dash'], workingDirectory: project);

      await expectLater(process.stdout, emitsThrough('Generating dash cli'));
      printOnFailure(await process.stdoutStream().join());
      printOnFailure(await process.stderrStream().join());
      await process.shouldExit(0);

      final entrypoint = File("${project.path}/dash");
      expect(entrypoint.existsSync(), isTrue);
      // check entrypoint is executable
      expect(entrypoint.statSync().modeString(), 'rwxr-xr-x');
    });
  });
}

Future<TestProcess> sidekickCli(
  List<String> args, {
  required Directory workingDirectory,
}) {
  return TestProcess.start(
    'dart',
    ['${Directory.current.path}/bin/sidekick.dart', ...args],
    workingDirectory: workingDirectory.path,
  );
}
