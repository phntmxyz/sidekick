import 'package:recase/recase.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  void setUpPackages(Directory tempDir) {
    final packages = [
      'foo/a',
      'foo/b',
      'foo/bar/baz',
      'test/a',
      'test/b',
    ];
    for (final package in packages) {
      final pubspec = tempDir.file('$package/pubspec.yaml')
        ..createSync(recursive: true);
      pubspec.writeAsStringSync('''
name: ${package.snakeCase}

environment:
  sdk: ^2.10.0
''');
    }
  }

  test('deps command gets dependencies for all packages ', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final fakeStdOut = FakeStdoutStream();
      await overrideIoStreams(
        stdout: () => fakeStdOut,
        body: () async {
          setUpPackages(dir);

          final runner = initializeSidekick(
            name: 'dash',
            dartSdkPath: systemDartSdkPath(),
          );
          runner.addCommand(DepsCommand());
          await runner.run(['deps']);
          expect(exitCode, 0);

          final expectedPackages = [
            'dash_sdk',
            'main_project',
            'foo_a',
            'foo_b',
            'foo_bar_baz',
            'test_a',
            'test_b',
          ].map((e) => yellow('=== package $e ==='));
          expect(fakeStdOut.lines, containsAll(expectedPackages));
        },
      );
    });
  });

  test('deps respects exclude parameters ', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final fakeStdOut = FakeStdoutStream();
      await overrideIoStreams(
        stdout: () => fakeStdOut,
        body: () async {
          setUpPackages(dir);

          final runner = initializeSidekick(
            name: 'dash',
            dartSdkPath: systemDartSdkPath(),
          );
          runner.addCommand(
            DepsCommand(
              // ignore: deprecated_member_use_from_same_package, until `exclude` is removed
              exclude: [DartPackage.fromDirectory(dir)!],
              excludedPackages: ['foo/**'],
            ),
          );
          await runner.run(['deps']);
          expect(exitCode, 0);

          final includedPackages = [
            'test_a',
            'test_b',
            'dash_sdk',
          ].map((e) => yellow('=== package $e ==='));
          expect(fakeStdOut.lines, containsAll(includedPackages));

          final excludedPackages = [
            'main_project',
            'foo_a',
            'foo_b',
            'foo_bar_baz',
          ].map((e) => yellow('=== package $e ==='));
          for (final excluded in excludedPackages) {
            expect(fakeStdOut.lines, isNot(anyElement(excluded)));
          }
        },
      );
    });
  });

  test('sets exitCode to 1 when getting deps fails in a package', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final fakeStderr = FakeStdoutStream();
      await overrideIoStreams(
        stderr: () => fakeStderr,
        body: () async {
          setUpPackages(dir);
          final brokenPubspec = dir.file('broken/pubspec.yaml')
            ..createSync(recursive: true)
            ..writeAsStringSync('name: broken');

          final runner = initializeSidekick(
            name: 'dash',
            dartSdkPath: systemDartSdkPath(),
          );
          runner.addCommand(DepsCommand());
          await runner.run(['deps']);

          expect(exitCode, 1);
          expect(
            fakeStderr.lines,
            containsAll([
              '\n\nErrors while getting dependencies:',
              startsWith(
                'broken: Failed to get dependencies for package ${brokenPubspec.parent.path}',
              )
            ]),
          );
        },
      );
    });
  });
}
