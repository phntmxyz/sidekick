import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_plugin_installer/sidekick_plugin_installer.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  group('Register plugin', () {
    test('A command gets added', () {
      insideFakeProjectWithSidekick((dir) async {
        dir.file('packages/dash/lib/dash.dart').writeAsStringSync(
              initialCliFileContentWithoutImportAndCommand,
            );
        registerPlugin(
          sidekickCli: DartPackage.fromDirectory(dir.directory('packages/dash'))!,
          command: 'MyCommand()',
        );
        expect(
          dir.file('packages/dash/lib/dash.dart').readAsStringSync(),
          initialCliFileContentWithMyCommand,
        );
      });
    });

    test('A command does not get double added if the command is already present', () {
      insideFakeProjectWithSidekick((dir) async {
        dir.file('packages/dash/lib/dash.dart').writeAsStringSync(
              initialCliFileContentWithMyCommand,
            );
        registerPlugin(
          sidekickCli: DartPackage.fromDirectory(dir.directory('packages/dash'))!,
          command: 'MyCommand()',
        );
        expect(
          dir.file('packages/dash/lib/dash.dart').readAsStringSync(),
          initialCliFileContentWithMyCommand,
        );
      });
    });

    test('A import gets added', () {
      insideFakeProjectWithSidekick((dir) async {
        dir.file('packages/dash/lib/dash.dart').writeAsStringSync(
              initialCliFileContentWithoutImportAndCommand,
            );
        registerPlugin(
          sidekickCli: DartPackage.fromDirectory(dir.directory('packages/dash'))!,
          import: "import 'package:my_package/src/my_command.dart';",
          command: 'MyCommand()',
        );
        expect(
          dir.file('packages/dash/lib/dash.dart').readAsStringSync(),
          initialCliFileContentWithMyImport,
        );
      });
    });
    test('A import does not get double added if the command is already present', () {
      insideFakeProjectWithSidekick((dir) async {
        dir.file('packages/dash/lib/dash.dart').writeAsStringSync(
              initialCliFileContentWithMyImport,
            );
        registerPlugin(
          sidekickCli: DartPackage.fromDirectory(dir.directory('packages/dash'))!,
          import: "import 'package:my_package/src/my_command.dart';",
          command: 'MyCommand()',
        );
        expect(
          dir.file('packages/dash/lib/dash.dart').readAsStringSync(),
          initialCliFileContentWithMyImport,
        );
      });
    });
  });

  group('throws error when arguments are not valid because', () {
    final packageDir = Directory.systemTemp.createTempSync();
    packageDir.file('pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: foo

environment:
  sdk: ^2.0.0
''');
    final package = DartPackage.fromDirectory(packageDir)!;
    test('gitUrl is required but is missing', () {
      expect(
        () => addDependency(
          package: package,
          dependency: 'foo',
          gitPath: 'bar',
        ),
        throwsA('git arguments were passed, but `gitUrl` was null.'),
      );
    });
    test('too many arguments are given', () {
      expect(
        () => addDependency(
          package: package,
          dependency: 'foo',
          gitPath: 'bar',
          localPath: 'baz',
        ),
        throwsA(
          'Too many arguments. Pass only one type of arguments (path/hosted/git).',
        ),
      );
    });
    packageDir.deleteSync(recursive: true);
  });
}

const initialCliFileContentWithoutImportAndCommand = '''
Future<void> runDash(List<String> args) async {
  final runner = initializeSidekick(
    name: 'dash',
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
''';
const initialCliFileContentWithMyImport = '''
import 'package:my_package/src/my_command.dart';Future<void> runDash(List<String> args) async {
  final runner = initializeSidekick(
    name: 'dash',
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
''';
const initialCliFileContentWithMyCommand = '''
Future<void> runDash(List<String> args) async {
  final runner = initializeSidekick(
    name: 'dash',
    flutterSdkPath: systemFlutterSdkPath(),
  );
  runner
    ..addCommand(DartCommand())
    ..addCommand(SidekickCommand())
    ..addCommand(MyCommand());
  try {
    return await runner.run(args);
  } on UsageException catch (e) {
    print(e);
    exit(64); // usage error
  }
}
''';
