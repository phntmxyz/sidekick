import 'dart:async';
import 'dart:convert';

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

  test('verbose mode streams test output in real-time', () async {
    await insideFakeProjectWithSidekick((dir) async {
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

      // Create a test with a delay to verify streaming happens during execution
      packageDir.file('test/streaming_test.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
import 'dart:async';
import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('test with delay', () async {
    // Print MARKER_START with >4KB to force buffer flush
    stdout.writeln('MARKER_START');
    for (var i = 0; i < 100; i++) {
      stdout.write('x' * 50);  // 50 chars * 100 = 5000 chars > 4KB
    }
    stdout.writeln();  // newline to complete the chunk
    stdout.flush();

    // Long delay before second marker
    await Future.delayed(Duration(seconds: 2));

    // Print MARKER_END with >4KB to force buffer flush
    stdout.writeln('MARKER_END');
    for (var i = 0; i < 100; i++) {
      stdout.write('y' * 50);
    }
    stdout.writeln();
    stdout.flush();

    expect(1 + 1, 2);
  });
}
''');

      final streams = FakeIoStreams();

      // Use Completers to track when markers appear in output
      final sawStartMarker = Completer<void>();
      final sawEndMarker = Completer<void>();

      // Track timestamps when markers appear
      DateTime? startTime;
      DateTime? endTime;

      // Wrap stdout to complete markers when they appear
      final wrappedStdout = FakeStdoutStream(onWrite: (text) {
        if (text.contains('MARKER_START') && !sawStartMarker.isCompleted) {
          startTime = DateTime.now();
          sawStartMarker.complete();
        }
        if (text.contains('MARKER_END') && !sawEndMarker.isCompleted) {
          endTime = DateTime.now();
          sawEndMarker.complete();
        }
        // Forward to original stdout
        streams.stdout.add(utf8.encode(text));
      });

      await overrideIoStreams(
        stdout: () => wrappedStdout,
        stderr: () => streams.stderr,
        body: () async {
          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());

          // Start the test command but don't await it yet
          final testFuture = runner.run(['test', '-p', 'pkg_a']);

          // Wait for MARKER_START to appear (should happen quickly)
          await sawStartMarker.future.timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('MARKER_START never appeared in output');
            },
          );

          // Now wait for MARKER_END to eventually appear
          await sawEndMarker.future.timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw TimeoutException('MARKER_END never appeared in output');
            },
          );

          // Wait for test to complete
          await testFuture;
        },
      );

      expect(exitCode, 0);

      // Verify timestamps were captured
      expect(startTime, isNotNull,
          reason: 'Should have captured MARKER_START timestamp');
      expect(endTime, isNotNull,
          reason: 'Should have captured MARKER_END timestamp');

      // Verify the markers appeared ~2 seconds apart (streaming proof)
      // If buffered, both would appear at nearly the same time (<50ms)
      final elapsed = endTime!.difference(startTime!);
      expect(
        elapsed.inMilliseconds,
        greaterThan(1800),
        reason:
            'MARKER_END should appear ~2000ms after MARKER_START if streaming works. '
            'Got ${elapsed.inMilliseconds}ms. If buffered, would be <50ms.',
      );
    });
  });

  test('fast mode does not stream detailed test output', () async {
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

          packageDir.file('test/streaming_test.dart')
            ..createSync(recursive: true)
            ..writeAsStringSync('''
import 'package:test/test.dart';

void main() {
  test('first test', () {
    print('Output from first test');
    expect(1 + 1, 2);
  });

  test('second test', () {
    print('Output from second test');
    expect(2 + 2, 4);
  });
}
''');

          final runner = initializeSidekick(
            dartSdkPath: testRunnerDartSdkPath(),
          );
          runner.addCommand(TestCommand());
          await runner.run(['test', '--fast', '-p', 'pkg_a']);

          expect(exitCode, 0);

          final output = streams.combined.join('\n');

          // Fast mode should NOT show individual test names or print statements
          expect(output, isNot(contains('Output from first test')));
          expect(output, isNot(contains('Output from second test')));
          // Should only show the summary line
          expect(output, contains('pkg_a'));
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
