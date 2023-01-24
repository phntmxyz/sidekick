import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';
import 'package:sidekick_core/src/update/patches/157_fix_usage_message.patch.dart';
import 'package:sidekick_core/src/update/patches/208_remove_cli_name.patch.dart';
import 'package:test/test.dart';

void main() {
  for (final testCase in _testCases) {
    test('patch 208 works (${testCase.name})', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final sidekickDir = tempDir.directory('dash_sidekick')..createSync();
      env['SIDEKICK_PACKAGE_HOME'] = sidekickDir.absolute.path;
      addTearDown(() {
        tempDir.deleteSync(recursive: true);
        env['SIDEKICK_PACKAGE_HOME'] = null;
      });
      tempDir.file('dash').writeAsString('# entrypoint file');
      sidekickDir.file('pubspec.yaml').writeAsStringSync('name: dash_sidekick');
      final cliMainFile = sidekickDir.file('lib/dash_sidekick.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(testCase.fileContentBefore);

      Object? error;
      await migrate(
        from: Version(0, 15, 1),
        to: Version(1, 0, 0),
        migrations: [fixUsageMessage208],
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
Future<void> runDash(List<String> args) async {
  final runner = initializeSidekick(
    flutterSdkPath: systemFlutterSdkPath(),
  );
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
Future<void> runDash(List<String> args) async {
  final runner = initializeSidekick(
    name: 'dash',
    flutterSdkPath: systemFlutterSdkPath(),
  );
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
        contains("name: 'dash',"),
        contains("lib/dash_sidekick.dart"),
        contains('github.com/phntmxyz/sidekick/pull/208'),
      ),
    ),
  ),
];
