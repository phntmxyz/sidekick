import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';
import 'package:sidekick_core/src/update/patches/272_add_sdk_initializer.patch.dart';
import 'package:test/test.dart';

void main() {
  test(
      'migrateAddSdkInitializer_272 replaces addFlutterSdkInitializer in user files',
      () async {
    final tempDir = Directory.systemTemp.createTempSync();
    env['SIDEKICK_ENTRYPOINT_HOME'] = tempDir.absolute.path;
    addTearDown(() {
      tempDir.deleteSync(recursive: true);
      env['SIDEKICK_ENTRYPOINT_HOME'] = null;
    });
    tempDir.file('dash').writeAsStringSync('# entrypoint file');

    // Create directories and test files with the old method name
    final libDir = tempDir.directory('lib')..createSync(recursive: true);
    final testDir = tempDir.directory('test')..createSync(recursive: true);
    final binDir = tempDir.directory('bin')..createSync(recursive: true);

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
    await migrate(
      from: Version(2, 1, 2),
      to: Version(3, 0, 1),
      migrations: [migrateAddSdkInitializer_272],
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

  test(
      'migrateAddSdkInitializer_272 does not modify files without the old method',
      () async {
    final tempDir = Directory.systemTemp.createTempSync();
    env['SIDEKICK_ENTRYPOINT_HOME'] = tempDir.absolute.path;
    addTearDown(() {
      tempDir.deleteSync(recursive: true);
      env['SIDEKICK_ENTRYPOINT_HOME'] = null;
    });
    tempDir.file('dash').writeAsStringSync('# entrypoint file');

    // Create directory and file without the old method name
    final libDir = tempDir.directory('lib')..createSync(recursive: true);
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
    await migrate(
      from: Version(2, 1, 2),
      to: Version(3, 0, 1),
      migrations: [migrateAddSdkInitializer_272],
    );

    // Verify the file was not changed
    final updatedContent = libFile.readAsStringSync();
    expect(updatedContent, originalContent);
  });
}
