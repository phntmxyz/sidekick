import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/format_command.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  void setupProject(
    Directory tempDir, {
    String? pubspecContent,
    required String mainContent,
  }) {
    if (pubspecContent != null) {
      final pubspec = tempDir.file('pubspec.yaml')..createSync();
      pubspec.writeAsStringSync(pubspecContent);
    }
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
      package = DartPackage.fromDirectory(temp)!;

      addTearDown(() {
        temp.deleteSync(recursive: true);
      });
    });
    test('no pubspec returns nothing', () {
      expect(getLineLength(package), isNull);
    });
    test('line_length argument is not present in pubspec returns nothing', () {
      pubspecYamlFile.writeAsStringSync('''
name: dashi
format:
''');
      expect(getLineLength(package), isNull);
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
    test('Should format the example folder different than /lib', () async {
      await insideFakeProjectWithSidekick((dir) async {
        setupProject(
          dir,
          pubspecContent: '''
name: dashi
''',
          mainContent: _dartFile140,
        );
        setupProject(
          dir.directory('example')..createSync(),
          pubspecContent: '''
name: dashi_example
format:
  line_length: 120
''',
          mainContent: _dartFile140,
        );
        final runner = initializeSidekick(
          dartSdkPath: systemDartSdkPath(),
        );
        runner.addCommand(FormatCommand());
        await runner.run(['format']);

        expect(exitCode, 0);
        expect(
          dir.file('lib/main.dart').readAsStringSync(),
          _dartFile80,
        );
        expect(
          dir.file('example/lib/main.dart').readAsStringSync(),
          _dartFile120,
        );
      });
    });

    test('Format the File to 80 if nothing else is set in Pubspec', () async {
      await insideFakeProjectWithSidekick((dir) async {
        setupProject(
          dir,
          pubspecContent: '''
name: dashi
''',
          mainContent: _dartFile140,
        );
        final runner = initializeSidekick(
          dartSdkPath: systemDartSdkPath(),
        );
        runner.addCommand(FormatCommand());
        await runner.run(['format']);

        expect(exitCode, 0);
        expect(
          dir.file('lib/main.dart').readAsStringSync(),
          _dartFile80,
        );
      });
    });

    test('defaultLineLength is applied when not specified in pubspec.yaml',
        () async {
      await insideFakeProjectWithSidekick((dir) async {
        setupProject(
          dir,
          pubspecContent: '''
name: dashi
''',
          mainContent: _dartFile140,
        );
        final runner = initializeSidekick(
          dartSdkPath: systemDartSdkPath(),
        );
        runner.addCommand(FormatCommand(defaultLineLength: 120));
        await runner.run(['format']);

        expect(exitCode, 0);
        expect(
          dir.file('lib/main.dart').readAsStringSync(),
          _dartFile120,
        );
      });
    });

    test('defaultLineLength is not applied when pubspec.yaml states a length',
        () async {
      await insideFakeProjectWithSidekick((dir) async {
        setupProject(
          dir,
          pubspecContent: '''
name: dashi

format:
  line_length: 100
''',
          mainContent: _dartFile140,
        );
        final runner = initializeSidekick(
          dartSdkPath: systemDartSdkPath(),
        );
        runner.addCommand(FormatCommand(defaultLineLength: 120));
        await runner.run(['format']);

        expect(exitCode, 0);
        expect(
          dir.file('lib/main.dart').readAsStringSync(),
          _dartFile100,
        );
      });
    });

    test('Format the File to 120 if set in PubspecYaml', () async {
      await insideFakeProjectWithSidekick((dir) async {
        setupProject(
          dir,
          pubspecContent: '''
name: dashi
format:
  line_length: 120
''',
          mainContent: _dartFile140,
        );
        final runner = initializeSidekick(
          dartSdkPath: systemDartSdkPath(),
        );
        runner.addCommand(FormatCommand());
        await runner.run(['format']);

        expect(exitCode, 0);
        expect(
          dir.file('lib/main.dart').readAsStringSync(),
          _dartFile120,
        );
      });
    });
    test('Format the File to 80 if set in PubspecYaml', () async {
      await insideFakeProjectWithSidekick((dir) async {
        setupProject(
          dir,
          pubspecContent: '''
name: dashi
format:
  line_length: 80
''',
          mainContent: _dartFile140,
        );
        final runner = initializeSidekick(
          dartSdkPath: systemDartSdkPath(),
        );
        runner.addCommand(FormatCommand());
        await runner.run(['format']);

        expect(exitCode, 0);
        expect(
          dir.file('lib/main.dart').readAsStringSync(),
          _dartFile80,
        );
      });
    });

    test('Excluding all Files in lib/', () async {
      await insideFakeProjectWithSidekick((dir) async {
        setupProject(
          dir,
          pubspecContent: '''
name: dashi
''',
          mainContent: _dartFile140,
        );
        final runner = initializeSidekick(
          dartSdkPath: systemDartSdkPath(),
        );
        runner.addCommand(
          FormatCommand(
            excludeGlob: ['lib/**'],
          ),
        );
        await runner.run(['format']);

        expect(exitCode, 0);
        expect(
          dir.file('lib/main.dart').readAsStringSync(),
          _dartFile140,
        );
      });
    });

    test('Excluding package build dir', () async {
      await insideFakeProjectWithSidekick((dir) async {
        setupProject(
          dir,
          pubspecContent: '''
name: dashi
''',
          mainContent: _dartFile140,
        );
        final buildFile = dir.file('build/build.dart')
          ..createSync(recursive: true);
        buildFile.writeAsStringSync(_dartFile140);

        final runner = initializeSidekick(dartSdkPath: systemDartSdkPath());
        runner.addCommand(FormatCommand());
        await runner.run(['format']);

        expect(exitCode, 0);
        expect(
          dir.file('lib/main.dart').readAsStringSync(),
          _dartFile80,
        );
        expect(
          dir.file('build/build.dart').readAsStringSync(),
          _dartFile140,
        );
      });
    });

    test('Exclude hidden folders', () async {
      await insideFakeProjectWithSidekick((dir) async {
        setupProject(
          dir,
          pubspecContent: '''
name: dashi
''',
          mainContent: _dartFile140,
        );
        final hiddenFolderFile = dir.file('.hidden/file.dart')
          ..createSync(recursive: true);
        hiddenFolderFile.writeAsStringSync(_dartFile140);

        final runner = initializeSidekick(dartSdkPath: systemDartSdkPath());
        runner.addCommand(FormatCommand());
        await runner.run(['format']);

        expect(exitCode, 0);
        expect(
          dir.file('lib/main.dart').readAsStringSync(),
          _dartFile80,
        );
        expect(
          dir.file('.hidden/file.dart').readAsStringSync(),
          _dartFile140,
        );
      });
    });
  });
}

const String _dartFile140 = '''
void main() {
  final forty = ['123456', '78901234'];
  final sixty = ['1234567890', '1234567890', '1234567890'];
  final eighty = ['1234567890', '1234567890', '1234567890', '1234567890', '1'];
  final hundred = ['1234567890', '1234567890', '1234567890', '1234567890', '1234567890', '123456'];
  final hundredTwenty = ['1234567890', '1234567890', '1234567890', '1234567890', '1234567890', '1234567890', '123456'];
  final hundredForty = ['1234567890', '1234567890', '1234567890', '1234567890', '1234567890', '1234567890', '1234567890', '1234567890123'];
}
''';

const String _dartFile80 = '''
void main() {
  final forty = ['123456', '78901234'];
  final sixty = ['1234567890', '1234567890', '1234567890'];
  final eighty = ['1234567890', '1234567890', '1234567890', '1234567890', '1'];
  final hundred = [
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '123456'
  ];
  final hundredTwenty = [
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '123456'
  ];
  final hundredForty = [
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890123'
  ];
}
''';

const String _dartFile100 = '''
void main() {
  final forty = ['123456', '78901234'];
  final sixty = ['1234567890', '1234567890', '1234567890'];
  final eighty = ['1234567890', '1234567890', '1234567890', '1234567890', '1'];
  final hundred = ['1234567890', '1234567890', '1234567890', '1234567890', '1234567890', '123456'];
  final hundredTwenty = [
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '123456'
  ];
  final hundredForty = [
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890123'
  ];
}
''';

const String _dartFile120 = '''
void main() {
  final forty = ['123456', '78901234'];
  final sixty = ['1234567890', '1234567890', '1234567890'];
  final eighty = ['1234567890', '1234567890', '1234567890', '1234567890', '1'];
  final hundred = ['1234567890', '1234567890', '1234567890', '1234567890', '1234567890', '123456'];
  final hundredTwenty = ['1234567890', '1234567890', '1234567890', '1234567890', '1234567890', '1234567890', '123456'];
  final hundredForty = [
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890123'
  ];
}
''';
