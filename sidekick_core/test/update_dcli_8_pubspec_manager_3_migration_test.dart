import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';
import 'package:sidekick_core/src/update/patches/280_update_dcli_8_pubspec_manager_3.patch.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  test('updates dcli to ^8.2.0 and pubspec_manager to ^3.0.0', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final pubspecFile = SidekickContext.sidekickPackage.pubspec;

      // Create a pubspec with older versions
      pubspecFile.writeAsStringSync('''
name: foo_sidekick
version: 1.0.0

environment:
  sdk: '>=3.6.0 <4.0.0'

dependencies:
  sidekick_core: ^3.0.0
  dcli: ^7.0.2
  pubspec_manager: ^2.0.0
''');

      await migrate(
        from: Version(3, 0, 0),
        to: Version(3, 1, 0),
        migrations: [updateDcli8PubspecManager3_280],
      );

      final content = pubspecFile.readAsStringSync();

      // Verify dcli was updated
      expect(content, contains('dcli: ^8.2.0'));
      expect(content, isNot(contains('dcli: ^7.0.2')));

      // Verify pubspec_manager was updated
      expect(content, contains('pubspec_manager: ^3.0.0'));
      expect(content, isNot(contains('pubspec_manager: ^2.0.0')));
    });
  });

  test('adds dcli if not present', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final pubspecFile = SidekickContext.sidekickPackage.pubspec;

      // Create a pubspec without dcli
      pubspecFile.writeAsStringSync('''
name: foo_sidekick
version: 1.0.0

environment:
  sdk: '>=3.6.0 <4.0.0'

dependencies:
  sidekick_core: ^3.0.0
  pubspec_manager: ^2.0.0
''');

      await migrate(
        from: Version(3, 0, 0),
        to: Version(3, 1, 0),
        migrations: [updateDcli8PubspecManager3_280],
      );

      final content = pubspecFile.readAsStringSync();
      expect(content, contains('dcli: ^8.2.0'));
    });
  });

  test('adds pubspec_manager if not present', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final pubspecFile = SidekickContext.sidekickPackage.pubspec;

      // Create a pubspec without pubspec_manager
      pubspecFile.writeAsStringSync('''
name: foo_sidekick
version: 1.0.0

environment:
  sdk: '>=3.6.0 <4.0.0'

dependencies:
  sidekick_core: ^3.0.0
  dcli: ^7.0.2
''');

      await migrate(
        from: Version(3, 0, 0),
        to: Version(3, 1, 0),
        migrations: [updateDcli8PubspecManager3_280],
      );

      final content = pubspecFile.readAsStringSync();
      expect(content, contains('pubspec_manager: ^3.0.0'));
    });
  });

  test('updates both dependencies when both are present with old versions', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final pubspecFile = SidekickContext.sidekickPackage.pubspec;

      pubspecFile.writeAsStringSync('''
name: foo_sidekick
version: 1.0.0

environment:
  sdk: '>=3.6.0 <4.0.0'

dependencies:
  sidekick_core: ^3.0.0
  dcli: ^4.0.1-beta.4
  pubspec_manager: ^1.0.0
''');

      await migrate(
        from: Version(3, 0, 0),
        to: Version(3, 1, 0),
        migrations: [updateDcli8PubspecManager3_280],
      );

      final content = pubspecFile.readAsStringSync();
      expect(content, contains('dcli: ^8.2.0'));
      expect(content, isNot(contains('dcli: ^4.0.1-beta.4')));
      expect(content, contains('pubspec_manager: ^3.0.0'));
      expect(content, isNot(contains('pubspec_manager: ^1.0.0')));
    });
  });

  test('does not run migration when upgrading from 3.1.0 to 3.2.0', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final pubspecFile = SidekickContext.sidekickPackage.pubspec;

      const originalContent = '''
name: foo_sidekick
version: 1.0.0

environment:
  sdk: '>=3.6.0 <4.0.0'

dependencies:
  sidekick_core: ^3.0.0
  dcli: ^7.0.2
  pubspec_manager: ^2.0.0
''';
      pubspecFile.writeAsStringSync(originalContent);

      await migrate(
        from: Version(3, 1, 0),
        to: Version(3, 2, 0),
        migrations: [updateDcli8PubspecManager3_280],
      );

      final content = pubspecFile.readAsStringSync();
      expect(content, originalContent);
    });
  });

  test('runs migration when upgrading from 3.0.0 to 3.1.0', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final pubspecFile = SidekickContext.sidekickPackage.pubspec;

      pubspecFile.writeAsStringSync('''
name: foo_sidekick
version: 1.0.0

environment:
  sdk: '>=3.6.0 <4.0.0'

dependencies:
  sidekick_core: ^3.0.0
  dcli: ^7.0.2
  pubspec_manager: ^2.0.0
''');

      await migrate(
        from: Version(3, 0, 0),
        to: Version(3, 1, 0),
        migrations: [updateDcli8PubspecManager3_280],
      );

      final content = pubspecFile.readAsStringSync();
      expect(content, contains('dcli: ^8.2.0'));
      expect(content, isNot(contains('dcli: ^7.0.2')));
      expect(content, contains('pubspec_manager: ^3.0.0'));
      expect(content, isNot(contains('pubspec_manager: ^2.0.0')));
    });
  });

  test('runs migration when upgrading from 2.0.0 to 3.2.0', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final pubspecFile = SidekickContext.sidekickPackage.pubspec;

      pubspecFile.writeAsStringSync('''
name: foo_sidekick
version: 1.0.0

environment:
  sdk: '>=3.6.0 <4.0.0'

dependencies:
  sidekick_core: ^3.0.0
  dcli: ^4.0.0
  pubspec_manager: ^1.0.0
''');

      await migrate(
        from: Version(2, 0, 0),
        to: Version(3, 2, 0),
        migrations: [updateDcli8PubspecManager3_280],
      );

      final content = pubspecFile.readAsStringSync();
      expect(content, contains('dcli: ^8.2.0'));
      expect(content, isNot(contains('dcli: ^4.0.0')));
      expect(content, contains('pubspec_manager: ^3.0.0'));
      expect(content, isNot(contains('pubspec_manager: ^1.0.0')));
    });
  });
}
