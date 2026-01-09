import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';
import 'package:sidekick_core/src/update/patches/278_add_test_command.patch.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  test('adds TestCommand after FormatCommand', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final mainFile = SidekickContext.sidekickPackage.cliMainFile;
      mainFile.writeAsStringSync('''
import 'package:sidekick_core/sidekick_core.dart';

void main() {
  final runner = initializeSidekick()
    ..addCommand(SidekickCommand())
    ..addCommand(FormatCommand());

  runner.run(args);
}
''');

      await migrate(
        from: Version(3, 0, 0),
        to: Version(3, 1, 0),
        migrations: [addTestCommand278],
      );

      final content = mainFile.readAsStringSync();
      expect(content, contains('..addCommand(TestCommand())'));
      expect(
        content,
        contains(
          '..addCommand(FormatCommand())\n    ..addCommand(TestCommand())',
        ),
      );
    });
  });

  test('adds TestCommand after SidekickCommand if FormatCommand not present',
      () async {
    await insideFakeProjectWithSidekick((dir) async {
      final mainFile = SidekickContext.sidekickPackage.cliMainFile;
      mainFile.writeAsStringSync('''
import 'package:sidekick_core/sidekick_core.dart';

void main() {
  final runner = initializeSidekick()
    ..addCommand(SidekickCommand())
    ..addCommand(DepsCommand());

  runner.run(args);
}
''');

      await migrate(
        from: Version(3, 0, 0),
        to: Version(3, 1, 0),
        migrations: [addTestCommand278],
      );

      final content = mainFile.readAsStringSync();
      expect(content, contains('..addCommand(TestCommand())'));
      expect(
        content,
        contains(
          '..addCommand(SidekickCommand())\n    ..addCommand(TestCommand())',
        ),
      );
    });
  });

  test('skips when TestCommand already exists', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final mainFile = SidekickContext.sidekickPackage.cliMainFile;
      const originalContent = '''
import 'package:sidekick_core/sidekick_core.dart';

void main() {
  final runner = initializeSidekick()
    ..addCommand(SidekickCommand())
    ..addCommand(TestCommand());

  runner.run(args);
}
''';
      mainFile.writeAsStringSync(originalContent);

      bool errorOccurred = false;
      await migrate(
        from: Version(3, 0, 0),
        to: Version(3, 1, 0),
        migrations: [addTestCommand278],
        onMigrationStepError: (context) {
          errorOccurred = true;
          expect(
            context.exception.toString(),
            contains('Test command already exists'),
          );
          return MigrationErrorHandling.skip;
        },
      );

      expect(errorOccurred, isTrue);
      expect(mainFile.readAsStringSync(), originalContent);
    });
  });

  test('skips when no suitable location found', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final mainFile = SidekickContext.sidekickPackage.cliMainFile;
      const originalContent = '''
import 'package:sidekick_core/sidekick_core.dart';

void main() {
  final runner = initializeSidekick();
  runner.run(args);
}
''';
      mainFile.writeAsStringSync(originalContent);

      bool errorOccurred = false;
      await migrate(
        from: Version(3, 0, 0),
        to: Version(3, 1, 0),
        migrations: [addTestCommand278],
        onMigrationStepError: (context) {
          errorOccurred = true;
          expect(
            context.exception.toString(),
            contains('Could not find a suitable location'),
          );
          return MigrationErrorHandling.skip;
        },
      );

      expect(errorOccurred, isTrue);
      expect(mainFile.readAsStringSync(), originalContent);
    });
  });

  test('does not run migration when upgrading from 3.1.0 to 3.2.0', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final mainFile = SidekickContext.sidekickPackage.cliMainFile;
      const originalContent = '''
import 'package:sidekick_core/sidekick_core.dart';

void main() {
  final runner = initializeSidekick()
    ..addCommand(SidekickCommand())
    ..addCommand(FormatCommand());

  runner.run(args);
}
''';
      mainFile.writeAsStringSync(originalContent);

      await migrate(
        from: Version(3, 1, 0),
        to: Version(3, 2, 0),
        migrations: [addTestCommand278],
      );

      final content = mainFile.readAsStringSync();
      expect(content, originalContent);
      expect(content, isNot(contains('TestCommand')));
    });
  });

  test('runs migration when upgrading from 3.0.0 to 3.1.0', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final mainFile = SidekickContext.sidekickPackage.cliMainFile;
      mainFile.writeAsStringSync('''
import 'package:sidekick_core/sidekick_core.dart';

void main() {
  final runner = initializeSidekick()
    ..addCommand(SidekickCommand())
    ..addCommand(FormatCommand());

  runner.run(args);
}
''');

      await migrate(
        from: Version(3, 0, 0),
        to: Version(3, 1, 0),
        migrations: [addTestCommand278],
      );

      final content = mainFile.readAsStringSync();
      expect(content, contains('..addCommand(TestCommand())'));
    });
  });

  test('runs migration when upgrading from 2.0.0 to 3.2.0', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final mainFile = SidekickContext.sidekickPackage.cliMainFile;
      mainFile.writeAsStringSync('''
import 'package:sidekick_core/sidekick_core.dart';

void main() {
  final runner = initializeSidekick()
    ..addCommand(SidekickCommand())
    ..addCommand(FormatCommand());

  runner.run(args);
}
''');

      await migrate(
        from: Version(2, 0, 0),
        to: Version(3, 2, 0),
        migrations: [addTestCommand278],
      );

      final content = mainFile.readAsStringSync();
      expect(content, contains('..addCommand(TestCommand())'));
    });
  });
}
