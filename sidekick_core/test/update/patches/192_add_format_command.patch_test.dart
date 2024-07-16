import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';
import 'package:sidekick_core/src/update/patches/192_add_format_command.patch.dart';
import 'package:test/test.dart';

void main() {
  for (final testCase in _testCases) {
    test('patch 192 works (${testCase.name})', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final sidekickDir = tempDir.directory('dash_sidekick')..createSync();
      env['SIDEKICK_PACKAGE_HOME'] = sidekickDir.absolute.path;
      addTearDown(() {
        tempDir.deleteSync(recursive: true);
        env['SIDEKICK_PACKAGE_HOME'] = null;
      });
      tempDir.file('dash').writeAsStringSync('# entrypoint file');
      sidekickDir.file('pubspec.yaml').writeAsStringSync('name: dash_sidekick');
      final cliMainFile = sidekickDir.file('lib/dash_sidekick.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync(testCase.fileContentBefore);

      Object? error;
      await migrate(
        from: Version(1, 0, 0),
        to: Version(1, 1, 0),
        migrations: [addFormatCommand192],
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
    ..addCommand(SidekickCommand())
    ..addCommand(FormatCommand());

  try {
    return await runner.run(args);
  } on UsageException catch (e) {
    print(e);
    exit(64); // usage error
  }
}
''';

const _caseWithExludeGlob = '''
Future<void> runDash(List<String> args) async {
  final runner = initializeSidekick(
    flutterSdkPath: systemFlutterSdkPath(),
  );
  runner
    ..addCommand(DartCommand())
    ..addCommand(SidekickCommand())
    ..addCommand(FormatCommand(excludeGlob: ['**/*.g.dart']));

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
        contains("Format command already exists"),
        contains("lib/dash_sidekick.dart"),
        contains('github.com/phntmxyz/sidekick/pull/192'),
      ),
    ),
  ),
  _TestCase(
    name: 'patch was already applied with excludeGlob',
    fileContentBefore: _caseWithExludeGlob,
    fileContentAfter: _caseWithExludeGlob,
    errorMatcher: isA<String>().having(
      (e) => e,
      'error',
      allOf(
        contains("Format command already exists"),
        contains("lib/dash_sidekick.dart"),
        contains('github.com/phntmxyz/sidekick/pull/192'),
      ),
    ),
  ),
];
