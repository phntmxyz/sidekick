import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';
import 'package:sidekick_core/src/update/patches/157_fix_usage_message.patch.dart';
import 'package:test/test.dart';

void main() {
  for (final testCase in _testCases) {
    test('patch 157 works (${testCase.name})', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final sidekickDir = tempDir.directory('test_sidekick')..createSync();
      env['SIDEKICK_PACKAGE_HOME'] = sidekickDir.absolute.path;
      addTearDown(() {
        tempDir.deleteSync(recursive: true);
        env['SIDEKICK_PACKAGE_HOME'] = null;
      });
      tempDir.file('test').writeAsStringSync('# entrypoint file');
      sidekickDir.file('pubspec.yaml').writeAsStringSync('name: test_sidekick');
      final cliMainFile = sidekickDir.file('lib/test_sidekick.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(testCase.fileContentBefore);

      Object? error;
      await migrate(
        from: Version(0, 13, 1),
        to: Version(0, 13, 2),
        migrations: fixUsageMessage157Patches,
        onMigrationStepError: (context) {
          error = context.exception;
          return MigrationErrorHandling.skip;
        },
      );

      expect(cliMainFile.readAsStringSync(), testCase.fileContentAfter);
      if (testCase.errorMatcher != null) {
        expect(error, testCase.errorMatcher);
      }
    });
  }
}

class _TestCase {
  _TestCase({
    required this.name,
    required this.fileContentBefore,
    required this.fileContentAfter,
    this.errorMatcher,
  });

  final String name;
  final String fileContentBefore;
  final String fileContentAfter;
  final Matcher? errorMatcher;
}

const _expectedResult = '''
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
''';

final _testCases = [
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
    fileContentAfter: _expectedResult,
  ),
  _TestCase(
    name: 'if(args.isEmpty) block was already removed',
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
    print(e.usage);
    exit(64); // usage error
  }
}
''',
    fileContentAfter: _expectedResult,
  ),
  _TestCase(
    name: 'print(e.usage) was already fixed',
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
    print(e);
    exit(64); // usage error
  }
}
''',
    fileContentAfter: _expectedResult,
  ),
  _TestCase(
    name: 'patch was already applied',
    fileContentBefore: _expectedResult,
    fileContentAfter: _expectedResult,
    errorMatcher: isA<String>().having(
      (e) => e,
      'error',
      allOf(
        contains("Couldn't apply git patch"),
        contains('Fix usage message (2/2)'),
        contains('} on UsageException catch (e) {'),
        contains('github.com/phntmxyz/sidekick/pull/157'),
      ),
    ),
  ),
];
