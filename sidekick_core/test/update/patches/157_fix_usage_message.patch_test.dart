import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';
import 'package:sidekick_core/src/update/patches/157_fix_usage_message.patch.dart';
import 'package:test/test.dart';

void main() {
  test('patch 157 works', () async {
    final tempDir = Directory.systemTemp.createTempSync();
    'git init'.start(workingDirectory: tempDir.path);
    env['SIDEKICK_PACKAGE_HOME'] = tempDir.absolute.path;
    addTearDown(() {
      tempDir.deleteSync(recursive: true);
      env['SIDEKICK_PACKAGE_HOME'] = null;
    });
    tempDir.file('pubspec.yaml').writeAsStringSync('name: test_sidekick');
    final cliMainFile = tempDir.file('lib/test_sidekick.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'dart:async';

import 'package:sidekick_core/sidekick_core.dart';
import 'package:test_sidekick/src/commands/bump_version_command.dart';
import 'package:test_sidekick/src/release/sidekick_bundled_version_bump.dart';
import 'package:test_sidekick/src/release/sidekick_core_bundled_version_bump.dart';
import 'package:test_sidekick/src/test_project.dart';

late TestProject testProject;

Future<void> runTest(List<String> args) async {
  final runner = initializeSidekick(
    name: 'test',
    flutterSdkPath: systemFlutterSdkPath(),
  );

  testProject = TestProject(runner.repository.root);
  runner
    ..addCommand(DartCommand())
    ..addCommand(SidekickCommand());

  if (args.isEmpty) {
    print(runner.usage);
    return;
  }

  try {
    return await runner.run(args);
  } on UsageException catch (e) {
    print(e.usage);
    exit(64); // usage error
  }
}
''');

    await migrate(
      from: Version(0, 13, 1),
      to: Version(0, 13, 2),
      migrations: [fixUsageMessagePatch157],
    );

    expect(cliMainFile.readAsStringSync(), '''
import 'dart:async';

import 'package:sidekick_core/sidekick_core.dart';
import 'package:test_sidekick/src/commands/bump_version_command.dart';
import 'package:test_sidekick/src/release/sidekick_bundled_version_bump.dart';
import 'package:test_sidekick/src/release/sidekick_core_bundled_version_bump.dart';
import 'package:test_sidekick/src/test_project.dart';

late TestProject testProject;

Future<void> runTest(List<String> args) async {
  final runner = initializeSidekick(
    name: 'test',
    flutterSdkPath: systemFlutterSdkPath(),
  );

  testProject = TestProject(runner.repository.root);
  runner
    ..addCommand(DartCommand())
    ..addCommand(SidekickCommand());

  try {
    return await runner.run(args);
  } on UsageException catch (e) {
    print(e);
    exit(64); // usage error
  }
}
''');
  });
}
