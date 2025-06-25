import 'dart:io';

import 'package:sidekick_core/sidekick_core.dart' hide equals;
import 'package:sidekick_core/src/update/migration.dart';
import 'package:sidekick_core/src/update/patches/272_add_sdk_initializer.patch.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  test(
      'migrateAddSdkInitializer_272 replaces addFlutterSdkInitializer in user files',
      () async {
    await insideFakeProjectWithSidekick((dir) async {
      // Create directories and test files with the old method name
      final libDir = dir.directory('lib')..createSync(recursive: true);
      final testDir = dir.directory('test')..createSync(recursive: true);
      final binDir = dir.directory('bin')..createSync(recursive: true);

      final libFile = libDir.file('main.dart');
      libFile.writeAsStringSync('''
import 'package:sidekick_core/sidekick_core.dart';

void main() {
  final runner = initializeSidekick();
  runner.addFlutterSdkInitializer((context) {
    // initialization code
  });
}
''');

      final testFile = testDir.file('test.dart');
      testFile.writeAsStringSync('''
import 'package:sidekick_core/sidekick_core.dart';

void testFunction() {
  addFlutterSdkInitializer((context) {
    // test initialization
  });
}
''');

      final binFile = binDir.file('script.dart');
      binFile.writeAsStringSync('''
import 'package:sidekick_core/sidekick_core.dart';

void scriptMain() {
  addFlutterSdkInitializer((context) {
    // script initialization
  });
}
''');

      // Apply the migration
      await migrateAddSdkInitializer_272.migrate(
        MigrationContext(
          step: migrateAddSdkInitializer_272,
          from: Version(2, 1, 2),
          to: Version(3, 0, 0),
        ),
      );

      // Verify the files were updated
      final updatedLibContent = libFile.readAsStringSync();
      final updatedTestContent = testFile.readAsStringSync();
      final updatedBinContent = binFile.readAsStringSync();

      expect(updatedLibContent, contains('addSdkInitializer'));
      expect(updatedLibContent, isNot(contains('addFlutterSdkInitializer')));
      expect(updatedTestContent, contains('addSdkInitializer'));
      expect(updatedTestContent, isNot(contains('addFlutterSdkInitializer')));
      expect(updatedBinContent, contains('addSdkInitializer'));
      expect(updatedBinContent, isNot(contains('addFlutterSdkInitializer')));
    });
  });

  test(
      'migrateAddSdkInitializer_272 does not modify files without the old method',
      () async {
    await insideFakeProjectWithSidekick((dir) async {
      // Create directory and file without the old method name
      final libDir = dir.directory('lib')..createSync(recursive: true);
      final libFile = libDir.file('main.dart');

      const originalContent = '''
import 'package:sidekick_core/sidekick_core.dart';

void main() {
  final runner = initializeSidekick();
  addSdkInitializer((context) {
    // already updated code
  });
}
''';
      libFile.writeAsStringSync(originalContent);

      // Apply the migration
      await migrateAddSdkInitializer_272.migrate(
        MigrationContext(
          step: migrateAddSdkInitializer_272,
          from: Version(2, 1, 2),
          to: Version(3, 0, 0),
        ),
      );

      // Verify the file was not changed
      final updatedContent = libFile.readAsStringSync();
      expect(updatedContent, equals(originalContent));
    });
  });
}
