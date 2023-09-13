import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';
import 'package:sidekick_core/src/update_sidekick_cli.dart'
    as update_entrypoint;
import 'package:sidekick_core/src/version_checker.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  test('Update major dependencies when migrating from 1.X to 2.X', () async {
    final tempDir = Directory.systemTemp.createTempSync();
    final sidekickDir = tempDir.directory('test_sidekick')..createSync();
    env['SIDEKICK_PACKAGE_HOME'] = sidekickDir.absolute.path;
    addTearDown(() {
      tempDir.deleteSync(recursive: true);
      env['SIDEKICK_PACKAGE_HOME'] = null;
    });
    tempDir.file('test').writeAsString('# entrypoint file');
    final pubspecFile = sidekickDir.file('pubspec.yaml');
    final oldHttpVersion = Version(0, 13, 6);
    pubspecFile.writeAsStringSync('''
name: test_sidekick

environment:
  sdk: '>=2.12.0 <3.0.0'

dependencies:
  # http updated to 1.0.0 with Dart 3 
  http: ^$oldHttpVersion
''');

    overrideSidekickDartRuntimeWithSystemDartRuntime(sidekickDir);

    // update the dart sdk. This is usually done beforehand by the [UpdateCommand]
    await migrate(
      from: Version(1, 0, 0),
      to: Version(2, 0, 0, pre: '1'),
      migrations: [
        MigrationStep.inline(
          (context) {
            final pubspec = pubspecFile;
            pubspec.replaceFirst(
              "sdk: '>=2.12.0 <3.0.0'",
              "sdk: '>=3.0.0 <4.0.0'",
            );
          },
          name: 'update sdk to 3.0',
          targetVersion: Version(2, 0, 0, pre: '1'),
        ),
      ],
      onMigrationStepStart: (context) {
        print('Starting migration step ${context.step.name}');
      },
    );
    print(pubspecFile.readAsStringSync());
    await update_entrypoint.main(['test_sidekick', '1.2.0', '2.0.0-preview.1']);

    print(pubspecFile.readAsStringSync());

    final Version? httpVersion = VersionChecker.getMinimumVersionConstraint(
      DartPackage.fromDirectory(sidekickDir)!,
      ['dependencies', 'http'],
    );

    expect(httpVersion, isNotNull);
    expect(httpVersion!.major, greaterThan(oldHttpVersion.major));

    final Version? coreVersion = VersionChecker.getMinimumVersionConstraint(
      DartPackage.fromDirectory(sidekickDir)!,
      ['dependencies', 'sidekick_core'],
    );

    expect(coreVersion, isNotNull);
    expect(coreVersion!.allows(Version.parse('2.0.0-preview.1')), isTrue);
  });
}
