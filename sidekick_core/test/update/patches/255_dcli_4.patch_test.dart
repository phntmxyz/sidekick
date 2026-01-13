import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';
import 'package:sidekick_core/src/update/patches/255_dcli_4.patch.dart';
import 'package:test/test.dart';

void main() {
  for (final testCase in _testCases) {
    test('patch 255 works (${testCase.name})', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final sidekickDir = tempDir.directory('dash_sidekick')..createSync();
      await withEnvironmentAsync(() async {
        env['SIDEKICK_ENTRYPOINT_FILE'] = null;
        tempDir.file('dash').writeAsStringSync('# entrypoint file');

        final pubspecFile = sidekickDir.file('pubspec.yaml');
        pubspecFile.writeAsStringSync(testCase.fileContentBefore);

        Object? error;
        await migrate(
          from: Version(2, 1, 2),
          to: Version(3, 0, 0, pre: 'preview.0'),
          migrations: [migrateDcli4_255],
          onMigrationStepError: (context) {
            error = context.exception;
            return MigrationErrorHandling.skip;
          },
        );

        expect(pubspecFile.readAsStringSync(), testCase.fileContentAfter);
        if (testCase.errorMatcher != null) {
          expect(error, testCase.errorMatcher);
        }
      }, environment: {
        'SIDEKICK_PACKAGE_HOME': sidekickDir.absolute.path,
      });
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

final _testCases = [
  _TestCase(
    name: 'default case',
    fileContentBefore: '''
name: dash_sidekick
environment:
  sdk: '>=3.3.0 <3.999.0'
dependencies:
  args: ^2.1.0
  cli_completion: ^0.3.0
  dartx: ^1.1.0
  dcli: ^2.2.3
  glob: ^2.0.2
''',
    fileContentAfter: '''
name: dash_sidekick
environment:
  sdk: '>=3.3.0 <3.999.0'
dependencies:
  args: ^2.1.0
  cli_completion: ^0.3.0
  dartx: ^1.1.0
  glob: ^2.0.2
  dcli: ^4.0.1-beta.4
''',
  ),
  _TestCase(
    name: 'no dcli before',
    fileContentBefore: '''
name: dash_sidekick
environment:
  sdk: '>=3.3.0 <3.999.0'
dependencies:
  args: ^2.1.0
  cli_completion: ^0.3.0
  dartx: ^1.1.0
  glob: ^2.0.2
''',
    fileContentAfter: '''
name: dash_sidekick
environment:
  sdk: '>=3.3.0 <3.999.0'
dependencies:
  args: ^2.1.0
  cli_completion: ^0.3.0
  dartx: ^1.1.0
  glob: ^2.0.2
  dcli: ^4.0.1-beta.4
''',
  ),
  _TestCase(
    name: 'patch was already applied',
    fileContentBefore: '''
name: dash_sidekick
environment:
  sdk: '>=3.3.0 <3.999.0'
dependencies:
  args: ^2.1.0
  cli_completion: ^0.3.0
  dartx: ^1.1.0
  glob: ^2.0.2
  dcli: ^2.2.3
''',
    fileContentAfter: '''
name: dash_sidekick
environment:
  sdk: '>=3.3.0 <3.999.0'
dependencies:
  args: ^2.1.0
  cli_completion: ^0.3.0
  dartx: ^1.1.0
  glob: ^2.0.2
  dcli: ^4.0.1-beta.4
''',
    errorMatcher: isNull,
  ),
];
