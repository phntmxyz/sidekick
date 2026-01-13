import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_test/fake_stdio.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart' hide isEmpty;

void main() {
  tearDown(() => exitCode = 0);

  test('runs all tests in all packages (verbose)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          createPackageWithTests(
            dir.directory('packages/pkg_a')..createSync(recursive: true),
            packageName: 'pkg_a',
          );
          createPackageWithTests(
            dir.directory('packages/pkg_b')..createSync(recursive: true),
            packageName: 'pkg_b',
          );

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test']);

          expect(exitCode, 0);
          expect(
            streams.combined.where((line) => line.contains('testing')),
            containsAll([
              contains('testing pkg_a'),
              contains('testing pkg_b'),
            ]),
          );
        },
      );
    });
  });

  test('runs all tests in all packages (fast)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          createPackageWithTests(
            dir.directory('packages/pkg_a')..createSync(recursive: true),
            packageName: 'pkg_a',
          );
          createPackageWithTests(
            dir.directory('packages/pkg_b')..createSync(recursive: true),
            packageName: 'pkg_b',
          );

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', '--fast']);

          expect(exitCode, 0);
          expect(
            streams.combined.where((line) => line.contains('testing')),
            containsAll([
              contains('testing pkg_a'),
              contains('testing pkg_b'),
            ]),
          );
        },
      );
    });
  });

  test('runs tests in a specific package by name (verbose)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          createPackageWithTests(
            dir.directory('packages/pkg_a')..createSync(recursive: true),
            packageName: 'pkg_a',
          );
          createPackageWithTests(
            dir.directory('packages/pkg_b')..createSync(recursive: true),
            packageName: 'pkg_b',
          );

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', '-p', 'pkg_a']);

          expect(exitCode, 0);
          expect(
            streams.combined.where((line) => line.contains('testing')),
            contains(contains('testing pkg_a')),
          );
          expect(
            streams.combined.any((line) => line.contains('testing pkg_b')),
            isFalse,
          );
        },
      );
    });
  });

  test('runs tests in a specific package by name (fast)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          createPackageWithTests(
            dir.directory('packages/pkg_a')..createSync(recursive: true),
            packageName: 'pkg_a',
          );
          createPackageWithTests(
            dir.directory('packages/pkg_b')..createSync(recursive: true),
            packageName: 'pkg_b',
          );

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', '--fast', '-p', 'pkg_a']);

          expect(exitCode, 0);
          expect(
            streams.combined.where((line) => line.contains('testing')),
            contains(contains('testing pkg_a')),
          );
          expect(
            streams.combined.any((line) => line.contains('testing pkg_b')),
            isFalse,
          );
        },
      );
    });
  });

  test('fails when package name not found', () async {
    await insideFakeProjectWithSidekick((dir) async {
      createPackageWithTests(
        dir.directory('packages/pkg_a')..createSync(recursive: true),
        packageName: 'pkg_a',
      );

      final runner = initializeSidekick(
        dartSdkPath: systemDartSdkPath(),
      );
      runner.addCommand(TestCommand());

      await expectLater(
        () => runner.run(['test', '-p', 'nonexistent']),
        throwsA(
          predicate(
            (e) => e.toString().contains('Could not find package nonexistent'),
          ),
        ),
      );
    });
  });

  test('runs tests for a specific file path (verbose)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          final packageDir = dir.directory('packages/pkg_a')
            ..createSync(recursive: true);
          createPackageWithTests(packageDir, packageName: 'pkg_a');

          final testFile = packageDir.file('test/specific_test.dart')
            ..createSync(recursive: true)
            ..writeAsStringSync('''
import 'package:test/test.dart';

void main() {
  test('specific test', () {
    expect(2 + 2, 4);
  });
}
''');

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', testFile.path]);

          expect(exitCode, 0);
          expect(
            streams.combined.join('\n'),
            contains('testing pkg_a test/specific_test.dart'),
          );
        },
      );
    });
  });

  test('runs tests for a specific file path (fast)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          final packageDir = dir.directory('packages/pkg_a')
            ..createSync(recursive: true);
          createPackageWithTests(packageDir, packageName: 'pkg_a');

          final testFile = packageDir.file('test/specific_test.dart')
            ..createSync(recursive: true)
            ..writeAsStringSync('''
import 'package:test/test.dart';

void main() {
  test('specific test', () {
    expect(2 + 2, 4);
  });
}
''');

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', '--fast', testFile.path]);

          expect(exitCode, 0);
          expect(
            streams.combined.join('\n'),
            contains('testing pkg_a test/specific_test.dart'),
          );
        },
      );
    });
  });

  test('runs tests for a specific directory path (verbose)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          final packageDir = dir.directory('packages/pkg_a')
            ..createSync(recursive: true);
          createPackageWithTests(packageDir, packageName: 'pkg_a');

          final testDir = packageDir.directory('test/unit')
            ..createSync(recursive: true);
          testDir.file('unit_test.dart').writeAsStringSync('''
import 'package:test/test.dart';

void main() {
  test('unit test', () {
    expect(3 + 3, 6);
  });
}
''');

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', testDir.path]);

          expect(exitCode, 0);
          expect(
            streams.combined.join('\n'),
            contains('testing pkg_a test/unit'),
          );
        },
      );
    });
  });

  test('runs tests for a specific directory path (fast)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          final packageDir = dir.directory('packages/pkg_a')
            ..createSync(recursive: true);
          createPackageWithTests(packageDir, packageName: 'pkg_a');

          final testDir = packageDir.directory('test/unit')
            ..createSync(recursive: true);
          testDir.file('unit_test.dart').writeAsStringSync('''
import 'package:test/test.dart';

void main() {
  test('unit test', () {
    expect(3 + 3, 6);
  });
}
''');

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', '--fast', testDir.path]);

          expect(exitCode, 0);
          expect(
            streams.combined.join('\n'),
            contains('testing pkg_a test/unit'),
          );
        },
      );
    });
  });

  test('runs tests for package root directory (verbose)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          final packageDir = dir.directory('packages/pkg_a')
            ..createSync(recursive: true);
          createPackageWithTests(packageDir, packageName: 'pkg_a');

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', packageDir.path]);

          expect(exitCode, 0);
          expect(
            streams.combined.where((line) => line.contains('testing')),
            contains(contains('testing pkg_a...')),
          );
        },
      );
    });
  });

  test('runs tests for package root directory (fast)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          final packageDir = dir.directory('packages/pkg_a')
            ..createSync(recursive: true);
          createPackageWithTests(packageDir, packageName: 'pkg_a');

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', '--fast', packageDir.path]);

          expect(exitCode, 0);
          expect(
            streams.combined.where((line) => line.contains('testing')),
            contains(contains('testing pkg_a...')),
          );
        },
      );
    });
  });

  test('fails when path has no package', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final runner = initializeSidekick(
        dartSdkPath: systemDartSdkPath(),
      );
      runner.addCommand(TestCommand());

      // Use a path outside the project directory
      final tempDir = Directory.systemTemp.createTempSync('no_package');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final testFile = tempDir.file('test.dart');

      await expectLater(
        () => runner.run(['test', testFile.path]),
        throwsA(
          predicate(
            (e) =>
                e.toString().contains('Could not determine package for path'),
          ),
        ),
      );
    });
  });

  test('shows message for packages with no tests (verbose)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          createPackageWithTests(
            dir.directory('packages/pkg_a')..createSync(recursive: true),
            packageName: 'pkg_a',
            createTests: false,
          );

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', '-p', 'pkg_a']);

          expect(exitCode, -1);
          expect(
            streams.combined.join('\n'),
            contains('pkg_a (no tests)'),
          );
        },
      );
    });
  });

  test('shows message for packages with no tests (fast)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          createPackageWithTests(
            dir.directory('packages/pkg_a')..createSync(recursive: true),
            packageName: 'pkg_a',
            createTests: false,
          );

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', '--fast', '-p', 'pkg_a']);

          expect(exitCode, -1);
          expect(
            streams.combined.join('\n'),
            contains('pkg_a (no tests)'),
          );
        },
      );
    });
  });

  test('--fast flag shows minimal output', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          createPackageWithTests(
            dir.directory('packages/pkg_a')..createSync(recursive: true),
            packageName: 'pkg_a',
          );

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', '--fast']);

          expect(exitCode, 0);
          expect(
            streams.combined.join('\n'),
            contains('testing pkg_a'),
          );
        },
      );
    });
  });

  test('--name option filters tests by name (verbose)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          final packageDir = dir.directory('packages/pkg_a')
            ..createSync(recursive: true);
          packageDir.file('pubspec.yaml')
            ..createSync(recursive: true)
            ..writeAsStringSync('''
name: pkg_a

environment:
  sdk: ^3.0.0

dev_dependencies:
  test: any
''');

          packageDir.file('test/example_test.dart')
            ..createSync(recursive: true)
            ..writeAsStringSync('''
import 'package:test/test.dart';

void main() {
  test('first test', () {
    expect(1 + 1, 2);
  });

  test('second test', () {
    expect(2 + 2, 4);
  });
}
''');

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', '-n', 'first']);

          expect(exitCode, 0);
        },
      );
    });
  });

  test('--name option filters tests by name (fast)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          final packageDir = dir.directory('packages/pkg_a')
            ..createSync(recursive: true);
          packageDir.file('pubspec.yaml')
            ..createSync(recursive: true)
            ..writeAsStringSync('''
name: pkg_a

environment:
  sdk: ^3.0.0

dev_dependencies:
  test: any
''');

          packageDir.file('test/example_test.dart')
            ..createSync(recursive: true)
            ..writeAsStringSync('''
import 'package:test/test.dart';

void main() {
  test('first test', () {
    expect(1 + 1, 2);
  });

  test('second test', () {
    expect(2 + 2, 4);
  });
}
''');

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', '--fast', '-n', 'first']);

          expect(exitCode, 0);
        },
      );
    });
  });

  test('sets exit code to -1 when tests fail', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          final packageDir = dir.directory('packages/pkg_a')
            ..createSync(recursive: true);
          packageDir.file('pubspec.yaml')
            ..createSync(recursive: true)
            ..writeAsStringSync('''
name: pkg_a

environment:
  sdk: ^3.0.0

dev_dependencies:
  test: any
''');

          packageDir.file('test/failing_test.dart')
            ..createSync(recursive: true)
            ..writeAsStringSync('''
import 'package:test/test.dart';

void main() {
  test('failing test', () {
    expect(1 + 1, 3);
  });
}
''');

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          // Use --fast to minimize confusing output from intentionally failing tests
          await runner.run(['test', '--fast']);

          expect(exitCode, -1);
          // Check combined output since that's what users see in their terminal
          expect(
            streams.combined.join('\n'),
            contains('pkg_a'),
          );
        },
      );
    });
  });

  test('mixes packages with and without tests (verbose)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          createPackageWithTests(
            dir.directory('packages/pkg_with_tests')
              ..createSync(recursive: true),
            packageName: 'pkg_with_tests',
          );
          createPackageWithTests(
            dir.directory('packages/pkg_without_tests')
              ..createSync(recursive: true),
            packageName: 'pkg_without_tests',
            createTests: false,
          );

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test']);

          expect(exitCode, 0);
          expect(
            streams.combined.join('\n'),
            allOf(
              contains('testing pkg_with_tests'),
              contains('pkg_without_tests (no tests)'),
            ),
          );
        },
      );
    });
  });

  test('mixes packages with and without tests (fast)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          createPackageWithTests(
            dir.directory('packages/pkg_with_tests')
              ..createSync(recursive: true),
            packageName: 'pkg_with_tests',
          );
          createPackageWithTests(
            dir.directory('packages/pkg_without_tests')
              ..createSync(recursive: true),
            packageName: 'pkg_without_tests',
            createTests: false,
          );

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', '--fast']);

          expect(exitCode, 0);
          expect(
            streams.combined.join('\n'),
            allOf(
              contains('testing pkg_with_tests'),
              contains('pkg_without_tests (no tests)'),
            ),
          );
        },
      );
    });
  });

  test('uses correct workingDirectory for each package (verbose)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          // Create two packages with tests that output their working directory
          final pkgADir = dir.directory('packages/pkg_a')
            ..createSync(recursive: true);
          pkgADir.file('pubspec.yaml')
            ..createSync(recursive: true)
            ..writeAsStringSync('''
name: pkg_a

environment:
  sdk: ^3.0.0

dev_dependencies:
  test: any
''');
          pkgADir.file('test/working_dir_test.dart')
            ..createSync(recursive: true)
            ..writeAsStringSync('''
import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('working directory is pkg_a', () {
    final cwd = Directory.current.path;
    print('Working directory: \$cwd');
    expect(cwd.endsWith('pkg_a'), isTrue, reason: 'Expected cwd to end with pkg_a, got: \$cwd');
  });
}
''');

          final pkgBDir = dir.directory('packages/pkg_b')
            ..createSync(recursive: true);
          pkgBDir.file('pubspec.yaml')
            ..createSync(recursive: true)
            ..writeAsStringSync('''
name: pkg_b

environment:
  sdk: ^3.0.0

dev_dependencies:
  test: any
''');
          pkgBDir.file('test/working_dir_test.dart')
            ..createSync(recursive: true)
            ..writeAsStringSync('''
import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('working directory is pkg_b', () {
    final cwd = Directory.current.path;
    print('Working directory: \$cwd');
    expect(cwd.endsWith('pkg_b'), isTrue, reason: 'Expected cwd to end with pkg_b, got: \$cwd');
  });
}
''');

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test']);

          // Both tests should pass, meaning each ran in its correct working directory
          expect(exitCode, 0);
          expect(
            streams.combined.join('\n'),
            allOf(
              contains('testing pkg_a'),
              contains('testing pkg_b'),
            ),
          );
        },
      );
    });
  });

  test('uses correct workingDirectory for each package (fast)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          // Create two packages with tests that output their working directory
          final pkgADir = dir.directory('packages/pkg_a')
            ..createSync(recursive: true);
          pkgADir.file('pubspec.yaml')
            ..createSync(recursive: true)
            ..writeAsStringSync('''
name: pkg_a

environment:
  sdk: ^3.0.0

dev_dependencies:
  test: any
''');
          pkgADir.file('test/working_dir_test.dart')
            ..createSync(recursive: true)
            ..writeAsStringSync('''
import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('working directory is pkg_a', () {
    final cwd = Directory.current.path;
    print('Working directory: \$cwd');
    expect(cwd.endsWith('pkg_a'), isTrue, reason: 'Expected cwd to end with pkg_a, got: \$cwd');
  });
}
''');

          final pkgBDir = dir.directory('packages/pkg_b')
            ..createSync(recursive: true);
          pkgBDir.file('pubspec.yaml')
            ..createSync(recursive: true)
            ..writeAsStringSync('''
name: pkg_b

environment:
  sdk: ^3.0.0

dev_dependencies:
  test: any
''');
          pkgBDir.file('test/working_dir_test.dart')
            ..createSync(recursive: true)
            ..writeAsStringSync('''
import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('working directory is pkg_b', () {
    final cwd = Directory.current.path;
    print('Working directory: \$cwd');
    expect(cwd.endsWith('pkg_b'), isTrue, reason: 'Expected cwd to end with pkg_b, got: \$cwd');
  });
}
''');

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', '--fast']);

          // Both tests should pass, meaning each ran in its correct working directory
          expect(exitCode, 0);
          expect(
            streams.combined.join('\n'),
            allOf(
              contains('testing pkg_a'),
              contains('testing pkg_b'),
            ),
          );
        },
      );
    });
  });

  test('deprecated --all flag still works (verbose)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          createPackageWithTests(
            dir.directory('packages/pkg_a')..createSync(recursive: true),
            packageName: 'pkg_a',
          );

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', '--all']);

          expect(exitCode, 0);
        },
      );
    });
  });

  test('deprecated --all flag still works (fast)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          createPackageWithTests(
            dir.directory('packages/pkg_a')..createSync(recursive: true),
            packageName: 'pkg_a',
          );

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', '--fast', '--all']);

          expect(exitCode, 0);
        },
      );
    });
  });

  test('path argument takes precedence over --package flag (verbose)',
      () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          final packageDir = dir.directory('packages/pkg_a')
            ..createSync(recursive: true);
          createPackageWithTests(packageDir, packageName: 'pkg_a');

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());

          await runner.run([
            'test',
            '-p',
            'pkg_b', // This should be ignored
            packageDir.file('test/example_test.dart').path,
          ]);

          expect(exitCode, 0);
          // Should run test from path, not from pkg_b
          expect(
            streams.combined.join('\n'),
            contains('testing pkg_a test/example_test.dart'),
          );
        },
      );
    });
  });

  test('path argument takes precedence over --package flag (fast)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          final packageDir = dir.directory('packages/pkg_a')
            ..createSync(recursive: true);
          createPackageWithTests(packageDir, packageName: 'pkg_a');

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());

          await runner.run([
            'test',
            '--fast',
            '-p',
            'pkg_b', // This should be ignored
            packageDir.file('test/example_test.dart').path,
          ]);

          expect(exitCode, 0);
          // Should run test from path, not from pkg_b
          expect(
            streams.combined.join('\n'),
            contains('testing pkg_a test/example_test.dart'),
          );
        },
      );
    });
  });

  test('handles path with trailing slash (verbose)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          final packageDir = dir.directory('packages/pkg_a')
            ..createSync(recursive: true);
          createPackageWithTests(packageDir, packageName: 'pkg_a');

          final testDir = packageDir.directory('test');

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', '${testDir.path}/']);

          expect(exitCode, 0);
          expect(
            streams.combined.join('\n'),
            contains('testing pkg_a test'),
          );
        },
      );
    });
  });

  test('handles path with trailing slash (fast)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          final packageDir = dir.directory('packages/pkg_a')
            ..createSync(recursive: true);
          createPackageWithTests(packageDir, packageName: 'pkg_a');

          final testDir = packageDir.directory('test');

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', '--fast', '${testDir.path}/']);

          expect(exitCode, 0);
          expect(
            streams.combined.join('\n'),
            contains('testing pkg_a test'),
          );
        },
      );
    });
  });

  test('runs tests from package root with trailing slash (verbose)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          final packageDir = dir.directory('packages/pkg_a')
            ..createSync(recursive: true);
          createPackageWithTests(packageDir, packageName: 'pkg_a');

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', '${packageDir.path}/']);

          expect(exitCode, 0);
          expect(
            streams.combined.where((line) => line.contains('testing')),
            contains(contains('testing pkg_a...')),
          );
        },
      );
    });
  });

  test('runs tests from package root with trailing slash (fast)', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final streams = FakeIoStreams();
      await overrideIoStreams(
        stdout: () => streams.stdout,
        stderr: () => streams.stderr,
        body: () async {
          final packageDir = dir.directory('packages/pkg_a')
            ..createSync(recursive: true);
          createPackageWithTests(packageDir, packageName: 'pkg_a');

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', '--fast', '${packageDir.path}/']);

          expect(exitCode, 0);
          expect(
            streams.combined.where((line) => line.contains('testing')),
            contains(contains('testing pkg_a...')),
          );
        },
      );
    });
  });
}

void createPackageWithTests(
  Directory packageDir, {
  required String packageName,
  bool isFlutter = false,
  bool createTests = true,
}) {
  final pubspecContent = '''
name: $packageName

environment:
  sdk: ^3.0.0

${isFlutter ? '''
dependencies:
  flutter:
    sdk: flutter
''' : ''}

dev_dependencies:
  test: any
''';

  packageDir.file('pubspec.yaml')
    ..createSync(recursive: true)
    ..writeAsStringSync(pubspecContent);

  if (createTests) {
    packageDir.file('test/example_test.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'package:test/test.dart';

void main() {
  test('example test', () {
    expect(1 + 1, 2);
  });
}
''');
  }
}
