import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';
import 'package:sidekick_core/src/update/patches/157_fix_usage_message.patch.dart';
import 'package:test/test.dart';

void main() {
  for (final testCase in _testCases) {
    test('patch 157 works (${testCase.name})', () async {
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
        ..writeAsStringSync(testCase.fileContentBefore);

      await migrate(
        from: Version(0, 13, 1),
        to: Version(0, 13, 2),
        migrations: [fixUsageMessagePatch157],
      );

      expect(cliMainFile.readAsStringSync(), testCase.fileContentAfter);
    });
  }
}

class _TestCase {
  const _TestCase({
    required this.name,
    required this.fileContentBefore,
    required this.fileContentAfter,
  });

  final String name;
  final String fileContentBefore;
  final String fileContentAfter;
}

const _testCases = [
  _TestCase(
    name: 'default case',
    fileContentBefore: '''
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
''',
    fileContentAfter: '''
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
''',
  ),
  _TestCase(
    name: 'patch was already applied',
    fileContentBefore: '''
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
''',
    fileContentAfter: '''
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
''',
  ),
];
