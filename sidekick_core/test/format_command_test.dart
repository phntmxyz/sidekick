import 'package:dcli/dcli.dart' hide isEmpty;
import 'package:sidekick_core/sidekick_core.dart' hide isEmpty;
import 'package:sidekick_core/src/commands/format_command.dart';
import 'package:sidekick_test/fake_stdio.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    final version = await getTesterDartVersion();
    stdout.writeln('using Dart SDK $version');
    if (version >= Version(3, 7, 0)) {
      stdout.writeln('which automatically adds trailing commas');
      _trailingComma = ',';
    } else {
      stdout.writeln('no trailing commas');
      _trailingComma = '';
    }
  });

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

  tearDown(() => exitCode = 0);

  group('getLineLength', () {
    late File pubspecYamlFile;
    late File analysisOptionsFile;
    late DartPackage package;

    setUp(() {
      final temp = Directory.systemTemp.createTempSync();
      pubspecYamlFile = temp.file('pubspec.yaml')..writeAsStringSync('''
name: dashi
''');
      analysisOptionsFile = temp.file('analysis_options.yaml')
        ..writeAsStringSync('');
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
    test('should return the line_length from analysis_options.yaml', () {
      analysisOptionsFile.writeAsStringSync('''
formatter:  
  page_width: 120
      ''');
      expect(getLineLength(package), 120);
    });
    test('analysis_options.yaml has precedence over pubspec.yaml', () {
      analysisOptionsFile.writeAsStringSync('''
formatter:  
  page_width: 120
      ''');
      pubspecYamlFile.writeAsStringSync('''
name: dashi
format:
  line_length: 100
''');
      expect(getLineLength(package), 120);
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
          dartSdkPath: testRunnerDartSdkPath(),
        );
        runner.addCommand(FormatCommand());
        await runner.run(['format']);

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
          dartSdkPath: testRunnerDartSdkPath(),
        );
        runner.addCommand(FormatCommand());
        await runner.run(['format']);

        expect(dir.file('lib/main.dart').readAsStringSync(), _dartFile80);
      });
    });

    test('Formats a single package', () async {
      await insideFakeProjectWithSidekick((dir) async {
        setupProject(
          dir.directory('dashi')..createSync(),
          pubspecContent: '''
name: dashi
''',
          mainContent: _dartFile140,
        );
        setupProject(
          dir.directory('moshi')..createSync(),
          pubspecContent: '''
name: moshi
''',
          mainContent: _dartFile140,
        );
        final runner = initializeSidekick(
          dartSdkPath: testRunnerDartSdkPath(),
        );

        SdkInitializerContext? sdkInitializerContext;
        addSdkInitializer((context) {
          sdkInitializerContext = context;
        });
        runner.addCommand(FormatCommand());
        await runner.run(['format', '-p', 'moshi']);

        expect(
          dir.file('dashi/lib/main.dart').readAsStringSync(),
          _dartFile140,
        );
        expect(dir.file('moshi/lib/main.dart').readAsStringSync(), _dartFile80);
        expect(sdkInitializerContext!.packageDir!.name, 'moshi');
        expect(
          sdkInitializerContext!.workingDirectory!.path,
          dir.directory('moshi').path,
        );
      });
    });

    test('Formats files not in a package with default-line-length', () async {
      await insideFakeProjectWithSidekick((dir) async {
        dir.file('pubspec.yaml').deleteSync();
        dir.file('some.dart').writeAsStringSync(_dartFile140);
        final runner = initializeSidekick(
          dartSdkPath: testRunnerDartSdkPath(),
        );
        runner.addCommand(FormatCommand(defaultLineLength: 100));
        await runner.run(['format']);

        expect(dir.file('some.dart').readAsStringSync(), _dartFile100);
      });
    });

    test('Formats files not in a package by default with 80', () async {
      await insideFakeProjectWithSidekick((dir) async {
        dir.file('pubspec.yaml').deleteSync();
        dir.file('some.dart').writeAsStringSync(_dartFile140);
        final runner = initializeSidekick(
          dartSdkPath: testRunnerDartSdkPath(),
        );
        runner.addCommand(FormatCommand());
        await runner.run(['format']);

        expect(dir.file('some.dart').readAsStringSync(), _dartFile80);
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
          dartSdkPath: testRunnerDartSdkPath(),
        );
        runner.addCommand(FormatCommand(defaultLineLength: 120));
        await runner.run(['format']);

        expect(dir.file('lib/main.dart').readAsStringSync(), _dartFile120);
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
          dartSdkPath: testRunnerDartSdkPath(),
        );
        runner.addCommand(FormatCommand(defaultLineLength: 120));
        await runner.run(['format']);

        expect(dir.file('lib/main.dart').readAsStringSync(), _dartFile100);
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
          dartSdkPath: testRunnerDartSdkPath(),
        );
        runner.addCommand(FormatCommand());
        await runner.run(['format']);

        expect(dir.file('lib/main.dart').readAsStringSync(), _dartFile120);
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
          dartSdkPath: testRunnerDartSdkPath(),
        );
        runner.addCommand(FormatCommand());
        await runner.run(['format']);

        expect(dir.file('lib/main.dart').readAsStringSync(), _dartFile80);
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
          dartSdkPath: testRunnerDartSdkPath(),
        );
        runner.addCommand(
          FormatCommand(
            excludeGlob: ['lib/**'],
          ),
        );
        await runner.run(['format']);

        expect(dir.file('lib/main.dart').readAsStringSync(), _dartFile140);
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

        final runner = initializeSidekick(dartSdkPath: testRunnerDartSdkPath());
        runner.addCommand(FormatCommand());
        await runner.run(['format']);

        expect(dir.file('lib/main.dart').readAsStringSync(), _dartFile80);
        expect(dir.file('build/build.dart').readAsStringSync(), _dartFile140);
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

        final runner = initializeSidekick(dartSdkPath: testRunnerDartSdkPath());
        runner.addCommand(FormatCommand());
        await runner.run(['format']);

        expect(dir.file('lib/main.dart').readAsStringSync(), _dartFile80);
        expect(dir.file('.hidden/file.dart').readAsStringSync(), _dartFile140);
      });
    });

    test('formatGenerated = false', () async {
      await insideFakeProjectWithSidekick((dir) async {
        setupProject(
          dir,
          pubspecContent: '''
name: dashi
''',
          mainContent: _dartFile140,
        );
        final gFile = dir.file('file.g.dart')..createSync(recursive: true);
        gFile.writeAsStringSync(_dartFile140);

        final freezedFile = dir.file('file.freezed.dart')
          ..createSync(recursive: true);
        freezedFile.writeAsStringSync(_dartFile140);

        final runner = initializeSidekick(dartSdkPath: testRunnerDartSdkPath());
        runner.addCommand(FormatCommand(formatGenerated: false));
        await runner.run(['format']);

        expect(dir.file('lib/main.dart').readAsStringSync(), _dartFile80);
        expect(dir.file('file.g.dart').readAsStringSync(), _dartFile140);
        expect(dir.file('file.freezed.dart').readAsStringSync(), _dartFile140);
      });
    });

    test('default: formatGenerated = true', () async {
      await insideFakeProjectWithSidekick((dir) async {
        setupProject(
          dir,
          pubspecContent: '''
name: dashi
''',
          mainContent: _dartFile140,
        );
        final gFile = dir.file('file.g.dart')..createSync(recursive: true);
        gFile.writeAsStringSync(_dartFile140);

        final freezedFile = dir.file('file.freezed.dart')
          ..createSync(recursive: true);
        freezedFile.writeAsStringSync(_dartFile140);

        final runner = initializeSidekick(dartSdkPath: testRunnerDartSdkPath());
        runner.addCommand(FormatCommand());
        await runner.run(['format']);

        expect(dir.file('lib/main.dart').readAsStringSync(), _dartFile80);
        expect(dir.file('file.g.dart').readAsStringSync(), _dartFile80);
        expect(dir.file('file.freezed.dart').readAsStringSync(), _dartFile80);
      });
    });

    test('--verify throws, but does not format', () async {
      await insideFakeProjectWithSidekick((dir) async {
        final unformattedFile = dir.file('some.dart')
          ..writeAsStringSync(_dartFile140);
        final fakeStdout = FakeStdoutStream();
        final fakeStderr = FakeStdoutStream();
        await overrideIoStreams(
          stderr: () => fakeStderr,
          stdout: () => fakeStdout,
          body: () async {
            final runner = initializeSidekick(
              dartSdkPath: testRunnerDartSdkPath(),
            );
            runner.addCommand(FormatCommand());
            await expectLater(
              () => runner.run(['format', '--verify']),
              throwsA(isA<DartFileFormatException>()),
            );

            expect(dir.file('some.dart').readAsStringSync(), _dartFile140);
          },
        );

        expect(
          fakeStderr.lines,
          contains(
            stringContainsInOrder(
              [
                'Following Dart files are not formatted correctly:',
                unformattedFile.path,
                'Run "dash format" to format the code.',
              ],
            ),
          ),
        );
        // shouldn't print lines like `Changed x.dart`, `Formatted x files (y changed) in z seconds`
        expect(
          fakeStdout.lines,
          ['Verifying package:dash', 'Verifying package:main_project'],
        );
      });
    });

    test('prints informative output when formatting files', () async {
      await insideFakeProjectWithSidekick((dir) async {
        final fakeStdout = FakeStdoutStream();
        final fakeStderr = FakeStdoutStream();
        await overrideIoStreams(
          stderr: () => fakeStderr,
          stdout: () => fakeStdout,
          body: () async {
            setupProject(dir, mainContent: _dartFile80);
            final runner = initializeSidekick(
              dartSdkPath: testRunnerDartSdkPath(),
            );
            runner.addCommand(FormatCommand());
            await runner.run(['format']);
          },
        );

        expect(fakeStderr.lines, isEmpty);
        expect(
          fakeStdout.lines,
          containsAll(
            [
              'Formatting package:dash',
              stringContainsInOrder(
                ['Formatted', 'packages/dash/lib/dash_sidekick.dart'],
              ),
              stringContainsInOrder(
                ['Formatted', 'packages/dash/lib/src/dash_project.dart'],
              ),
              stringContainsInOrder(
                ['Formatted 2 files (2 changed) in', 'seconds'],
              ),
            ],
          ),
        );
      });
    });

    test('hides packages with no Dart files', () async {
      await insideFakeProjectWithSidekick((dir) async {
        final fakeStdout = FakeStdoutStream();
        final fakeStderr = FakeStdoutStream();
        await overrideIoStreams(
          stderr: () => fakeStderr,
          stdout: () => fakeStdout,
          body: () async {
            // Create a package with Dart files
            setupProject(
              dir.directory('package_with_dart')..createSync(),
              pubspecContent: '''
name: package_with_dart
''',
              mainContent: _dartFile140,
            );

            // Create a package with no Dart files (only pubspec.yaml)
            setupProject(
              dir.directory('package_without_dart')..createSync(),
              pubspecContent: '''
name: package_without_dart
''',
              mainContent: _dartFile140,
            );
            // Delete the Dart file to simulate a package with no Dart files
            dir
                .directory('package_without_dart')
                .file('lib/main.dart')
                .deleteSync();

            final runner = initializeSidekick(
              dartSdkPath: testRunnerDartSdkPath(),
            );
            runner.addCommand(FormatCommand());
            await runner.run(['format']);
          },
        );

        expect(fakeStderr.lines, isEmpty);
        expect(
          fakeStdout.lines,
          containsAll(
            [
              'Formatting package:package_with_dart',
              stringContainsInOrder(
                ['Formatted', 'package_with_dart/lib/main.dart'],
              ),
              stringContainsInOrder(
                ['Formatted 1 file (1 changed) in', 'seconds'],
              ),
              'Formatting package:package_without_dart',
              'No files to format',
            ],
          ),
        );

        // Should not contain any output for packages without Dart files
        expect(
          fakeStdout.lines,
          isNot(contains('package:empty_package')),
        );

        // Verify that package_without_dart appears in the output
        expect(
          fakeStdout.lines,
          contains('Formatting package:package_without_dart'),
        );
        expect(
          fakeStdout.lines,
          contains('No files to format'),
        );
      });
    });

    test('hides packages completely ignored by excludeGlob', () async {
      await insideFakeProjectWithSidekick((dir) async {
        final fakeStdout = FakeStdoutStream();
        final fakeStderr = FakeStdoutStream();
        await overrideIoStreams(
          stderr: () => fakeStderr,
          stdout: () => fakeStdout,
          body: () async {
            // Create a package with Dart files that should be formatted
            setupProject(
              dir.directory('package_to_format')..createSync(),
              pubspecContent: '''
name: package_to_format
''',
              mainContent: _dartFile140,
            );

            // Create a package with Dart files that should be completely ignored
            final ignoredPackage = dir.directory('ignored_package')
              ..createSync();
            ignoredPackage.file('pubspec.yaml').writeAsStringSync('''
name: ignored_package
''');
            ignoredPackage.file('lib/main.dart').createSync(recursive: true);
            ignoredPackage.file('lib/main.dart').writeAsStringSync('''
void main() {
  print("This package should be completely ignored");
}
''');

            final runner = initializeSidekick(
              dartSdkPath: testRunnerDartSdkPath(),
            );
            runner.addCommand(
              FormatCommand(
                excludeGlob: ['ignored_package/**'],
              ),
            );
            await runner.run(['format']);
          },
        );

        expect(fakeStderr.lines, isEmpty);
        expect(
          fakeStdout.lines,
          containsAll(
            [
              'Formatting package:package_to_format',
              stringContainsInOrder(
                ['Formatted', 'package_to_format/lib/main.dart'],
              ),
              stringContainsInOrder(
                ['Formatted 1 file (1 changed) in', 'seconds'],
              ),
            ],
          ),
        );

        // Should not contain any output for the completely ignored package
        expect(
          fakeStdout.lines,
          isNot(contains('package:ignored_package')),
        );
      });
    });

    test('single package mode always prints even if ignored', () async {
      await insideFakeProjectWithSidekick((dir) async {
        final fakeStdout = FakeStdoutStream();
        final fakeStderr = FakeStdoutStream();
        await overrideIoStreams(
          stderr: () => fakeStderr,
          stdout: () => fakeStdout,
          body: () async {
            // Create a package that will be ignored by excludeGlob
            setupProject(
              dir.directory('ignored_package')..createSync(),
              pubspecContent: '''
name: ignored_package
''',
              mainContent: _dartFile140,
            );

            final runner = initializeSidekick(
              dartSdkPath: testRunnerDartSdkPath(),
            );
            runner.addCommand(
              FormatCommand(
                excludeGlob: ['ignored_package/**'],
              ),
            );
            // Run in single package mode
            await runner.run(['format', '-p', 'ignored_package']);
          },
        );

        expect(fakeStderr.lines, isEmpty);
        expect(
          fakeStdout.lines,
          containsAll(
            [
              'Formatting package:ignored_package',
              'No files to format',
            ],
          ),
        );
      });
    });

    test('multi-package mode with only one package always prints', () async {
      await insideFakeProjectWithSidekick((dir) async {
        final fakeStdout = FakeStdoutStream();
        final fakeStderr = FakeStdoutStream();
        await overrideIoStreams(
          stderr: () => fakeStderr,
          stdout: () => fakeStdout,
          body: () async {
            dir.file('pubspec.yaml').deleteSync(); // delete main_project
            final runner = initializeSidekick(
              dartSdkPath: testRunnerDartSdkPath(),
            );
            runner.addCommand(
              FormatCommand(
                excludeGlob: ['packages/dash/**'],
              ),
            );
            // Run in multi-package mode (no -p flag)
            await runner.run(['format']);
          },
        );

        expect(fakeStderr.lines, isEmpty);
        // Should print the package even though it's ignored, because it's the only one
        expect(
          fakeStdout.lines,
          containsAll(
            [
              'Formatting package:dash',
              'No files to format',
            ],
          ),
        );
      });
    });

    test('single package mode with no dart files always prints', () async {
      await insideFakeProjectWithSidekick((dir) async {
        final fakeStdout = FakeStdoutStream();
        final fakeStderr = FakeStdoutStream();
        await overrideIoStreams(
          stderr: () => fakeStderr,
          stdout: () => fakeStdout,
          body: () async {
            // Create a package with no Dart files
            final packageDir = dir.directory('package_no_dart')..createSync();
            packageDir.file('pubspec.yaml').writeAsStringSync('''
name: package_no_dart
''');

            final runner = initializeSidekick(
              dartSdkPath: testRunnerDartSdkPath(),
            );
            runner.addCommand(FormatCommand());
            // Run in single package mode
            await runner.run(['format', '-p', 'package_no_dart']);
          },
        );

        expect(fakeStderr.lines, isEmpty);
        expect(
          fakeStdout.lines,
          containsAll(
            [
              'Formatting package:package_no_dart',
              'No files to format',
            ],
          ),
        );
      });
    });

    test('warns when all dart files are ignored', () async {
      await insideFakeProjectWithSidekick((dir) async {
        final fakeStdout = FakeStdoutStream();
        final fakeStderr = FakeStdoutStream();
        await overrideIoStreams(
          stderr: () => fakeStderr,
          stdout: () => fakeStdout,
          body: () async {
            // Create packages with Dart files
            setupProject(
              dir.directory('package1')..createSync(),
              pubspecContent: '''
name: package1
''',
              mainContent: _dartFile140,
            );
            setupProject(
              dir.directory('package2')..createSync(),
              pubspecContent: '''
name: package2
''',
              mainContent: _dartFile140,
            );

            final runner = initializeSidekick(
              dartSdkPath: testRunnerDartSdkPath(),
            );
            runner.addCommand(
              FormatCommand(
                excludeGlob: ['**/*.dart'], // Exclude all Dart files
              ),
            );
            await runner.run(['format']);
          },
        );

        expect(fakeStderr.lines, isEmpty);
        // Check for the warning message, accounting for ANSI color codes
        expect(
          fakeStdout.lines,
          anyElement(
            contains(
              'Warning: All Dart files in the project are excluded by glob patterns.',
            ),
          ),
        );
      });
    });

    test('warns when no dart files exist', () async {
      await insideFakeProjectWithSidekick((dir) async {
        final fakeStdout = FakeStdoutStream();
        final fakeStderr = FakeStdoutStream();
        await overrideIoStreams(
          stderr: () => fakeStderr,
          stdout: () => fakeStdout,
          body: () async {
            // Delete the default lib directory to remove Dart files
            final libDir = dir.directory('lib');
            if (libDir.existsSync()) {
              libDir.deleteSync(recursive: true);
            }
            // Delete Dart files from the packages directory
            final packagesDir = dir.directory('packages');
            if (packagesDir.existsSync()) {
              for (final package
                  in packagesDir.listSync().whereType<Directory>()) {
                final packageLibDir = package.directory('lib');
                if (packageLibDir.existsSync()) {
                  packageLibDir.deleteSync(recursive: true);
                }
              }
            }

            // Create packages with no Dart files
            final package1 = dir.directory('package1')..createSync();
            package1.file('pubspec.yaml').writeAsStringSync('''
name: package1
''');

            final runner = initializeSidekick(
              dartSdkPath: testRunnerDartSdkPath(),
            );
            runner.addCommand(FormatCommand());
            await runner.run(['format']);
          },
        );

        expect(fakeStderr.lines, isEmpty);
        // Check for the warning message, accounting for ANSI color codes
        expect(
          fakeStdout.lines,
          anyElement(contains('Warning: No Dart files found in the project.')),
        );
      });
    });

    test('excludes all Dart files and prints no package', () async {
      await insideFakeProjectWithSidekick((dir) async {
        final fakeStdout = FakeStdoutStream();
        final fakeStderr = FakeStdoutStream();
        await overrideIoStreams(
          stderr: () => fakeStderr,
          stdout: () => fakeStdout,
          body: () async {
            // Create two packages with Dart files
            setupProject(
              dir.directory('package1')..createSync(),
              pubspecContent: '''
name: package1
''',
              mainContent: _dartFile140,
            );
            setupProject(
              dir.directory('package2')..createSync(),
              pubspecContent: '''
name: package2
''',
              mainContent: _dartFile140,
            );

            final runner = initializeSidekick(
              dartSdkPath: testRunnerDartSdkPath(),
            );
            runner.addCommand(
              FormatCommand(
                excludeGlob: ['**/*.dart'],
              ),
            );
            await runner.run(['format']);
          },
        );

        // Should not print any package
        expect(
          fakeStdout.lines.where((l) => l.startsWith('Formatting package:')),
          isEmpty,
        );
      });
    });
  });
}

/// Returns the version of the Dart SDK used by the tester
/// by parsing the `dart --version` output.
Future<Version> getTesterDartVersion() async {
  final executable = Platform.executable;
  final progress =
      startFromArgs(executable, ['--version'], progress: Progress.capture());
  // Dart SDK version: 3.7.2 (stable) (Tue Mar 11 04:27:50 2025 -0700) on "macos_arm64"
  final String versionString = progress.firstLine!;
  final regex = RegExp(r'Dart SDK version: (\S+) ');
  final match = regex.firstMatch(versionString);
  return Version.parse(match!.group(1)!);
}

String? _trailingComma;
String get trailingComma => _trailingComma!;

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

final String _dartFile80 = '''
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
    '123456'$trailingComma
  ];
  final hundredTwenty = [
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '123456'$trailingComma
  ];
  final hundredForty = [
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890123'$trailingComma
  ];
}
''';

final String _dartFile100 = '''
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
    '123456'$trailingComma
  ];
  final hundredForty = [
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890',
    '1234567890123'$trailingComma
  ];
}
''';

final String _dartFile120 = '''
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
    '1234567890123'$trailingComma
  ];
}
''';
