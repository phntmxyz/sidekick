import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update_sidekick_cli.dart'
    as update_entrypoint;
import 'package:sidekick_core/src/version_checker.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  test('Update major dependencies when migrating from 2.X to 3.X', () async {
    final tempDir = Directory.systemTemp.createTempSync();
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final sidekickDir = tempDir.directory('test_sidekick')..createSync();
    await withEnvironmentAsync(() async {
      env['SIDEKICK_ENTRYPOINT_FILE'] = null;
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
      await update_entrypoint.main(['test_sidekick', '2.1.2', '3.0.0']);

      final Version? dcliVersion = VersionChecker.getMinimumVersionConstraint(
        DartPackage.fromDirectory(sidekickDir)!,
        ['dependencies', 'dcli'],
      );

      expect(dcliVersion, isNotNull);
      expect(
        dcliVersion!.allows(Version.parse('7.0.2')),
        isTrue,
        reason:
            'Expected dcli version to be at least 7.0.2, but got $dcliVersion',
      );

      final Version? coreVersion = VersionChecker.getMinimumVersionConstraint(
        DartPackage.fromDirectory(sidekickDir)!,
        ['dependencies', 'sidekick_core'],
      );

      expect(coreVersion, isNotNull);
      expect(coreVersion!.allows(Version.parse('3.0.0')), isTrue);
    }, environment: {
      'SIDEKICK_PACKAGE_HOME': sidekickDir.absolute.path,
    });
  });
}
