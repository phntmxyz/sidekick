import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_plugin_installer/sidekick_plugin_installer.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  late final Directory packageDir;
  late File pubspec;
  late DartPackage package;

  setUpAll(() {
    // it's necessary to use the same package path in every test because
    // addSelfAsDependency uses sidekickDartRuntime which is initialized only once
    // (final) with env.SIDEKICK_PACKAGE_HOME
    // if env.SIDEKICK_PACKAGE_HOME changes between tests,
    // sidekickDartRuntime breaks
    packageDir = Directory.systemTemp.createTempSync();
  });

  setUp(() {
    pubspec = packageDir.file('pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: foo

environment:
  sdk: ^2.0.0
''');
    package = DartPackage.fromDirectory(packageDir)!;
    overrideSidekickDartRuntimeWithSystemDartRuntime(packageDir);
  });

  tearDown(() {
    packageDir.deleteSync(recursive: true);
  });

  group('pubspec is correctly modified when', () {
    test('adding a local dependency', () {
      final barDir = Directory.systemTemp.createTempSync();
      addTearDown(() => barDir.deleteSync(recursive: true));
      barDir.file('pubspec.yaml').writeAsStringSync('''
name: bar

environment:
  sdk: ^2.0.0
''');

      addDependency(
        package: package,
        dependency: 'bar',
        localPath: barDir.path,
      );

      expect(
        pubspec.readAsStringSync(),
        '''
name: foo

environment:
  sdk: ^2.0.0
dependencies:
  bar:
    path: ${barDir.path}
''',
      );
    });

    test('adding a hosted dependency', () {
      addDependency(
        package: package,
        dependency: 'sidekick_core',
        versionConstraint: '^0.10.0',
      );

      expect(
        pubspec.readAsStringSync(),
        '''
name: foo

environment:
  sdk: ^2.0.0
dependencies:
  sidekick_core: ^0.10.0
''',
      );
    });

    test('adding a git dependency', () {
      addDependency(
        package: package,
        dependency: 'sidekick_core',
        gitUrl: 'https://github.com/phntmxyz/sidekick',
        gitPath: 'sidekick_core',
      );

      expect(
        pubspec.readAsStringSync(),
        '''
name: foo

environment:
  sdk: ^2.0.0
dependencies:
  sidekick_core:
    git:
      url: https://github.com/phntmxyz/sidekick
      path: sidekick_core
''',
      );
    });
    group('Register plugin', () {
      const initialCliFileContent = '''
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
\nimport 'package:my_package/src/my_command.dart';Future<void> runDash(List<String> args) async {
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

      test('A command gets added', () {
        insideFakeProjectWithSidekick((dir) async {
          dir.file('packages/dash/lib/dash.dart').writeAsStringSync(
                initialCliFileContent,
              );
          registerPlugin(
            sidekickCli:
                DartPackage.fromDirectory(dir.directory('packages/dash'))!,
            command: 'MyCommand()',
          );
          expect(
            dir.file('packages/dash/lib/dash.dart').readAsStringSync(),
            initialCliFileContentWithMyCommand,
          );
        });
      });

      test(
          'A command does not get double added if the command is already present',
          () {
        insideFakeProjectWithSidekick((dir) async {
          dir.file('packages/dash/lib/dash.dart').writeAsStringSync(
                initialCliFileContentWithMyCommand,
              );
          registerPlugin(
            sidekickCli:
                DartPackage.fromDirectory(dir.directory('packages/dash'))!,
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
                initialCliFileContent,
              );
          registerPlugin(
            sidekickCli:
                DartPackage.fromDirectory(dir.directory('packages/dash'))!,
            import: "import 'package:my_package/src/my_command.dart';",
            command: 'MyCommand()',
          );
          expect(
            dir.file('packages/dash/lib/dash.dart').readAsStringSync(),
            initialCliFileContentWithMyImport,
          );
        });
      });
      test(
          'A import does not get double added if the command is already present',
          () {
        insideFakeProjectWithSidekick((dir) async {
          dir.file('packages/dash/lib/dash.dart').writeAsStringSync(
                initialCliFileContentWithMyImport,
              );
          registerPlugin(
            sidekickCli:
                DartPackage.fromDirectory(dir.directory('packages/dash'))!,
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
  });

  group('throws error when arguments are not valid because', () {
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
  });
}
