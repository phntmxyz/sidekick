import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_test/fake_stdio.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

const String mainFileUnformatted = '''
void main() {
  final test = ['Hello', 'World', 'This', 'is', 'a', 'test', 'for', 'the', 'format', 'command'];
}
''';
const String mainFileFormatted = '''
void main() {
  final test = [
    'Hello',
    'World',
    'This',
    'is',
    'a',
    'test',
    'for',
    'the',
    'format',
    'command'
  ];
}
''';

void main() {
  void setupProject(
    Directory tempDir, {
    required String pubspecContent,
    required String mainContent,
  }) {
    final pubspec = tempDir.file('pubspec.yaml')..createSync();
    pubspec.writeAsStringSync(pubspecContent);
    final mainFile = tempDir.file('lib/main.dart')..createSync(recursive: true);
    mainFile.writeAsStringSync(mainContent);
  }

  group('getLineLength', () {
    late File pubspecYamlFile;
    late DartPackage package;

    setUp(() {
      final temp = Directory.systemTemp.createTempSync();
      pubspecYamlFile = temp.file('pubspec.yaml')..writeAsStringSync('''
name: dashi
''');
      env['SIDEKICK_PACKAGE_HOME'] = temp.path;
      package = DartPackage.fromDirectory(temp)!;

      addTearDown(() {
        env['SIDEKICK_PACKAGE_HOME'] = null;
        temp.deleteSync(recursive: true);
      });
    });
    test(
        'should return 80 as default if format argument is not present in pubspec',
        () {
      expect(getLineLength(package), 80);
    });
    test(
        'should return 80 as default if line_length argument is not present in pubspec',
        () {
      pubspecYamlFile.writeAsStringSync('''
name: dashi
format:
''');
      expect(getLineLength(package), 80);
    });
    test('should return the set line_length from the pubspec if present', () {
      pubspecYamlFile.writeAsStringSync('''
name: dashi
format:
  line_length: 123
''');
      expect(getLineLength(package), 123);
    });
  });
  group('Format Command', () {
    test('Format the File to 80 if nothing else is set in Pubspec', () async {
      await insideFakeProjectWithSidekick((dir) async {
        final fakeStdOut = FakeStdoutStream();
        await overrideIoStreams(
          stdout: () => fakeStdOut,
          body: () async {
            setupProject(
              dir,
              pubspecContent: '''
name: dashi
''',
              mainContent: mainFileUnformatted,
            );
            final runner = initializeSidekick(
              name: 'dash',
              dartSdkPath: systemDartSdkPath(),
            );
            runner.addCommand(FormatCommand());
            await runner.run(['format']);

            expect(exitCode, 0);
            expect(
              dir.file('lib/main.dart').readAsStringSync(),
              mainFileFormatted,
            );
          },
        );
      });
    });
    test('Format the File to 120 if set as Command Argument', () async {
      await insideFakeProjectWithSidekick((dir) async {
        final fakeStdOut = FakeStdoutStream();
        await overrideIoStreams(
          stdout: () => fakeStdOut,
          body: () async {
            setupProject(
              dir,
              pubspecContent: '''
name: dashi
''',
              mainContent: mainFileUnformatted,
            );
            final runner = initializeSidekick(
              name: 'dash',
              dartSdkPath: systemDartSdkPath(),
            );
            runner.addCommand(FormatCommand());
            await runner.run(['format', '--line-length', '120']);

            expect(exitCode, 0);
            expect(
              dir.file('lib/main.dart').readAsStringSync(),
              mainFileUnformatted,
            );
          },
        );
      });
    });
    test('Format the File to 120 if set in PubspecYaml', () async {
      await insideFakeProjectWithSidekick((dir) async {
        final fakeStdOut = FakeStdoutStream();
        await overrideIoStreams(
          stdout: () => fakeStdOut,
          body: () async {
            setupProject(
              dir,
              pubspecContent: '''
name: dashi
format:
  line_length: 120
''',
              mainContent: mainFileUnformatted,
            );
            final runner = initializeSidekick(
              name: 'dash',
              dartSdkPath: systemDartSdkPath(),
            );
            runner.addCommand(FormatCommand());
            await runner.run(['format']);

            expect(exitCode, 0);
            expect(
              dir.file('lib/main.dart').readAsStringSync(),
              mainFileUnformatted,
            );
          },
        );
      });
    });
    test('Format the File to 120 if set in PubspecYaml', () async {
      await insideFakeProjectWithSidekick((dir) async {
        final fakeStdOut = FakeStdoutStream();
        await overrideIoStreams(
          stdout: () => fakeStdOut,
          body: () async {
            setupProject(
              dir,
              pubspecContent: '''
name: dashi
format:
  line_length: 80
''',
              mainContent: mainFileUnformatted,
            );
            final runner = initializeSidekick(
              name: 'dash',
              dartSdkPath: systemDartSdkPath(),
            );
            runner.addCommand(FormatCommand());
            await runner.run(['format']);

            expect(exitCode, 0);
            expect(
              dir.file('lib/main.dart').readAsStringSync(),
              mainFileFormatted,
            );
          },
        );
      });
    });
    test('Excluding all Files in lib/', () async {
      await insideFakeProjectWithSidekick((dir) async {
        final fakeStdOut = FakeStdoutStream();
        await overrideIoStreams(
          stdout: () => fakeStdOut,
          body: () async {
            setupProject(
              dir,
              pubspecContent: '''
name: dashi
''',
              mainContent: mainFileUnformatted,
            );
            final runner = initializeSidekick(
              name: 'dash',
              dartSdkPath: systemDartSdkPath(),
            );
            runner.addCommand(
              FormatCommand(
                exclude: [DartPackage.flutter(dir.directory('lib'), 'Dash')],
              ),
            );
            await runner.run(['format']);

            expect(exitCode, 0);
            expect(
              dir.file('lib/main.dart').readAsStringSync(),
              mainFileUnformatted,
            );
          },
        );
      });
    });
  });
}
