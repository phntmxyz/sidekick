import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

import 'templates/templates.dart';
import 'util/cli_runner.dart';
import 'util/local_testing.dart';

void main() {
  late File entrypoint;
  late Directory projectRoot;

  Future<TestProcess> startDashProcess(Iterable<String> arguments) =>
      TestProcess.start(
        entrypoint.path,
        arguments,
        workingDirectory: projectRoot.path,
      );

  setUp(() async {
    projectRoot = setupTemplateProject('test/templates/root_with_packages');
    final process = await sidekickCli(
      ['init', '-n', 'dash'],
      workingDirectory: projectRoot,
    );
    await process.shouldExit(0);
    entrypoint = File("${projectRoot.path}/dash");
    expect(entrypoint.existsSync(), isTrue);

    if (shouldUseLocalDevs) {
      overrideSidekickCoreWithLocalPath(
        projectRoot.directory('packages/dash_sidekick'),
      );
    }
  });

  group('plugins add executes fine', () {
    test(
      'with hosted source',
      () async {
        final dashProcess =
            await startDashProcess(['plugins', 'add', 'sidekick_vault']);
        printOnFailure(await dashProcess.stdoutStream().join('\n'));
        printOnFailure(await dashProcess.stderrStream().join('\n'));
        dashProcess.shouldExit(0);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'with git source',
      () async {
        final dashProcess = await startDashProcess([
          'plugins',
          'add',
          '--source',
          'git',
          '--git-path',
          'packages/umbra_cli',
          'https://github.com/wolfenrain/umbra',
        ]);
        printOnFailure(await dashProcess.stdoutStream().join('\n'));
        printOnFailure(await dashProcess.stderrStream().join('\n'));
        dashProcess.shouldExit(0);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'with local source',
      () async {
        final dashProcess = await startDashProcess([
          'plugins',
          'add',
          '--source',
          'path',
          projectRoot.directory('packages/package_a').path,
        ]);
        printOnFailure(await dashProcess.stdoutStream().join('\n'));
        printOnFailure(await dashProcess.stderrStream().join('\n'));
        dashProcess.shouldExit(0);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}
