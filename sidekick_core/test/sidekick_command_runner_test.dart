import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/version_checker.dart';
import 'package:sidekick_test/fake_stdio.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    env['SIDEKICK_ENABLE_UPDATE_CHECK'] = 'true';
  });

  tearDown(() {
    addTearDown(() => env['SIDEKICK_ENABLE_UPDATE_CHECK'] = null);
  });

  final expectedCliVersionIntegrityWarnings = [
    contains('sidekick_core:0.0.2'),
    contains('sidekick.cli_version 0.0.1'),
    contains('dash sidekick update'),
  ];
  final expectedOutdatedWarning = '${yellow('Update available!')}\n'
      'Run ${cyan('dash sidekick update')} to update your CLI.';

  test('prints warnings to update outdated CLI', () async {
    fakeGetLatestDependencyVersion({'sidekick_core': Version(1, 0, 0)});
    final fakeStderr = FakeStdoutStream();
    await insideFakeProjectWithSidekick(
      (tempDir) async {
        await overrideIoStreams(
          stderr: () => fakeStderr,
          body: () async {
            final runner = initializeSidekick(name: 'dash');

            await runner.run(['-h']);

            final expectedWarnings = [
              ...expectedCliVersionIntegrityWarnings,
              contains(expectedOutdatedWarning),
            ];

            expect(fakeStderr.lines.join('\n'), allOf(expectedWarnings));
          },
        );
      },
      sidekickCoreVersion: "0.0.2",
      sidekickCliVersion: "0.0.1",
    );
  });

  test('prints no warnings when offline and versions match', () async {
    // empty map is equivalent to being offline
    fakeGetLatestDependencyVersion({});
    final fakeStderr = FakeStdoutStream();
    await insideFakeProjectWithSidekick(
      (tempDir) async {
        await overrideIoStreams(
          stderr: () => fakeStderr,
          body: () async {
            final runner = initializeSidekick(name: 'dash');

            await runner.run(['-h']);

            expect(fakeStderr.lines.isEmpty, isTrue);
          },
        );
      },
      sidekickCoreVersion: "0.0.1",
      sidekickCliVersion: "0.0.1",
    );
  });

  test('prints only warning to repair CLI when offline and versions mismatch',
      () async {
    // empty map is equivalent to being offline
    fakeGetLatestDependencyVersion({});
    final fakeStderr = FakeStdoutStream();
    await insideFakeProjectWithSidekick(
      (tempDir) async {
        await overrideIoStreams(
          stderr: () => fakeStderr,
          body: () async {
            final runner = initializeSidekick(name: 'dash');

            await runner.run(['-h']);

            expect(fakeStderr.lines.join('\n'),
                allOf(expectedCliVersionIntegrityWarnings));
          },
        );
      },
      sidekickCoreVersion: "0.0.2",
      sidekickCliVersion: "0.0.1",
    );
  });

  test('does not run update checks for `sidekick update`', () async {
    final fakeStderr = FakeStdoutStream();
    await insideFakeProjectWithSidekick(
      (tempDir) async {
        await overrideIoStreams(
          stderr: () => fakeStderr,
          body: () async {
            final runner = initializeSidekick(
              name: 'dash',
            );
            runner.addCommand(SidekickCommand());

            await runner.run(['sidekick', 'update', '-h']);

            expect(fakeStderr.lines.isEmpty, isTrue);
          },
        );
      },
      sidekickCoreVersion: "0.0.2",
      sidekickCliVersion: "0.0.1",
    );
  });

  test('runs update checks for other commands with `update` subcommand',
      () async {
    final fakeStderr = FakeStdoutStream();
    await insideFakeProjectWithSidekick(
      (tempDir) async {
        await overrideIoStreams(
          stderr: () => fakeStderr,
          body: () async {
            final runner = initializeSidekick(
              name: 'dash',
            );
            runner.addCommand(_WrapperCommand());

            await runner.run(['wrapper', 'update', '-h']);
            final expectedWarnings = [
              ...expectedCliVersionIntegrityWarnings,
              contains(expectedOutdatedWarning),
            ];

            expect(fakeStderr.lines.join('\n'), allOf(expectedWarnings));
          },
        );
      },
      sidekickCoreVersion: "0.0.2",
      sidekickCliVersion: "0.0.1",
    );
  });
}

class _WrapperCommand extends Command {
  @override
  final String description = 'Manages the sidekick CLI';

  @override
  final String name = 'wrapper';

  _WrapperCommand() {
    addSubcommand(_UpdateCommand());
  }
}

class _UpdateCommand extends Command {
  @override
  final String description = 'Fake update command';

  @override
  final String name = 'update';
}

void fakeGetLatestDependencyVersion(Map<String, Version> latestVersions) {
  VersionChecker.testFakeGetLatestDependencyVersion =
      (String dependency) async => latestVersions[dependency]!;
  addTearDown(() => VersionChecker.testFakeGetLatestDependencyVersion = null);
}
