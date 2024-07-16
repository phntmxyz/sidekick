import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';
import 'package:sidekick_core/src/update/patches/253_add_lock_file.patch.dart';
import 'package:test/test.dart';

void main() {
  for (final testCase in _testCases) {
    test('patch 253 works (${testCase.name})', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final sidekickDir = tempDir.directory('dash_sidekick')..createSync();
      env['SIDEKICK_PACKAGE_HOME'] = sidekickDir.absolute.path;
      addTearDown(() {
        tempDir.deleteSync(recursive: true);
        env['SIDEKICK_PACKAGE_HOME'] = null;
      });
      tempDir.file('dash').writeAsStringSync('# entrypoint file');
      sidekickDir.file('pubspec.yaml').writeAsStringSync('name: dash_sidekick');
      final gitignore = sidekickDir.file('.gitignore');
      gitignore.writeAsStringSync(testCase.fileContentBefore);

      Object? error;
      await migrate(
        from: Version(2, 1, 1),
        to: Version(2, 1, 2),
        migrations: [forceAddPubspecLock253],
        onMigrationStepError: (context) {
          error = context.exception;
          return MigrationErrorHandling.skip;
        },
      );

      expect(gitignore.readAsStringSync(), testCase.fileContentAfter);
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
# Files and directories created by pub
.dart_tool/
.packages
coverage/

# Conventional directory for build outputs
build/

# Directory created by dartdoc
doc/api/

# Lock dependencies for deterministic builds on all systems
!pubspec.lock
''';

final _testCases = [
  _TestCase(
    name: 'default case',
    fileContentBefore: '''
# Files and directories created by pub
.dart_tool/
.packages
coverage/

# Conventional directory for build outputs
build/

# Directory created by dartdoc
doc/api/

''',
    fileContentAfter: _expectedResult,
  ),
  _TestCase(
    name: 'custom .gitignore',
    fileContentBefore: '''
# Custom git ignore
some.file
''',
    fileContentAfter: '''
# Custom git ignore
some.file
# Lock dependencies for deterministic builds on all systems
!pubspec.lock
''',
  ),
  _TestCase(
    name: 'patch was already applied',
    fileContentBefore: _expectedResult,
    fileContentAfter: _expectedResult,
    errorMatcher: isNull,
  ),
];
