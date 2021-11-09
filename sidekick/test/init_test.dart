import 'dart:io';

import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

import 'templates/templates.dart';

void main() {
  group('project type detection', () {
    test('init for root with packages', () async {
      final project = setupTemplateProject('test/templates/root_with_packages');
      final process = await sidekickCli(['init'], workingDirectory: project);

      await expectLater(process.stderr, emitsThrough('TODO'));
      await process.shouldExit(255);

      // TODO check that creation worked
      // await process.shouldExit(0);
    });
  });
}

Future<TestProcess> sidekickCli(List<String> args,
    {required Directory workingDirectory}) {
  return TestProcess.start(
    'dart',
    ['${Directory.current.path}/bin/sidekick.dart', 'init'],
    workingDirectory: workingDirectory.path,
  );
}
