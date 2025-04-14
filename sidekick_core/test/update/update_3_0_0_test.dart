import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';
import 'package:sidekick_core/src/update/patches/260_dart_3_5_dcli_7.patch.dart';
import 'package:sidekick_core/src/update_sidekick_cli.dart'
    as update_entrypoint;
import 'package:sidekick_core/src/version_checker.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  test('Update major dependencies when migrating from 2.X to 3.X', () async {
    final tempDir = Directory.systemTemp.createTempSync();
    final sidekickDir = tempDir.directory('test_sidekick')..createSync();
    env['SIDEKICK_PACKAGE_HOME'] = sidekickDir.absolute.path;
    addTearDown(() {
      tempDir.deleteSync(recursive: true);
      env['SIDEKICK_PACKAGE_HOME'] = null;
    });
    tempDir.file('test').writeAsStringSync('# entrypoint file');
    final pubspecFile = sidekickDir.file('pubspec.yaml');
    final oldDcliVersion = Version(4, 0, 0);
    pubspecFile.writeAsStringSync('''
name: test_sidekick

environment:
  sdk: '>=2.0.0 <4.0.0'

dependencies:
  dcli: $oldDcliVersion
''');

    overrideSidekickDartRuntimeWithSystemDartRuntime(sidekickDir);

    // update the dart sdk. This is usually done beforehand by the [UpdateCommand]
    await migrate(
      from: Version(2, 1, 2),
      to: Version(3, 0, 0),
      migrations: [
        migrateDart35dcli7_260,
      ],
      onMigrationStepStart: (context) {
        print('Starting migration step ${context.step.name}');
      },
    );
    print(pubspecFile.readAsStringSync());
    await update_entrypoint.main(['test_sidekick', '2.1.2', '3.0.0']);

    final Version? dcliVersion = VersionChecker.getMinimumVersionConstraint(
      DartPackage.fromDirectory(sidekickDir)!,
      ['dependencies', 'dcli'],
    );

    expect(dcliVersion, isNotNull);
    expect(dcliVersion!.allows(Version.parse('7.0.2')), isTrue);

    final Version? coreVersion = VersionChecker.getMinimumVersionConstraint(
      DartPackage.fromDirectory(sidekickDir)!,
      ['dependencies', 'sidekick_core'],
    );

    expect(coreVersion, isNotNull);
    expect(coreVersion!.allows(Version.parse('3.0.0')), isTrue);
  });
}
