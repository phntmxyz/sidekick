import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/version_checker.dart';
import 'package:test/test.dart';

import 'util/cli_runner.dart';

void main() {
  test(
    'dart-internal command executes embedded Dart SDK',
    () async {
      await withSidekickCli((cli) async {
        // Get expected Dart version from sidekick package pubspec.yaml
        final sidekickPackage = cli.root.directory('dashi_sidekick');
        final dartPackage = DartPackage.fromDirectory(sidekickPackage)!;
        final expectedDartVersion = VersionChecker.getMinimumVersionConstraint(
          dartPackage,
          ['environment', 'sdk'],
        );
        expect(
          expectedDartVersion,
          isNotNull,
          reason: 'Could not read Dart SDK version from pubspec.yaml',
        );

        // Test dart-internal --version using cli.run
        final process =
            await cli.run(['sidekick', 'dart-internal', '--version']);

        final stdout = await process.stdoutStream().join('\n');
        printOnFailure('stdout: $stdout');

        // Verify output contains Dart version information
        expect(stdout, contains('Dart SDK version:'));

        // Verify it's using the expected Dart version from pubspec.yaml
        expect(
          stdout,
          contains(expectedDartVersion.toString()),
          reason:
              'Expected Dart version: $expectedDartVersion, but got: $stdout',
        );
      });
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'dart-internal help command works',
    () async {
      await withSidekickCli((cli) async {
        // Test dart-internal help using cli.run
        final process = await cli.run(['sidekick', 'dart-internal', 'help']);

        final stdout = await process.stdoutStream().join('\n');
        printOnFailure('stdout: $stdout');

        // Verify output contains Dart help information
        expect(stdout, contains('A command-line utility for Dart development'));
      });
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'dart-internal shows in sidekick help',
    () async {
      await withSidekickCli((cli) async {
        // Test sidekick help to see if dart-internal is listed using cli.run
        final process = await cli.run(['sidekick', '--help']);

        final stdout = await process.stdoutStream().join('\n');
        printOnFailure('stdout: $stdout');

        // Verify dart-internal command is listed in help
        expect(stdout, contains('dart-internal'));
      });
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
