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
    projectRoot = setupTemplateProject('test/templates/minimal_dart_package');
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

  group('plugins install executes fine', () {
    test(
      'with default hosted source',
      () async {
        final dashProcess =
            await startDashProcess(['plugins', 'install', 'sidekick_vault']);
        printOnFailure(await dashProcess.stdoutStream().join('\n'));
        printOnFailure(await dashProcess.stderrStream().join('\n'));
        dashProcess.shouldExit(0);
      },
      timeout: const Timeout(Duration(minutes: 5)),
      skip: 'Wait for first plugin to be published',
    );

    test(
      'with custom hosted source',
      () async {
        final dashProcess = await startDashProcess([
          'plugins',
          'install',
          '--hosted-url',
          'https://pub.flutter-io.cn/',
          'sidekick_vault',
        ]);
        printOnFailure(await dashProcess.stdoutStream().join('\n'));
        printOnFailure(await dashProcess.stderrStream().join('\n'));
        dashProcess.shouldExit(0);
      },
      timeout: const Timeout(Duration(minutes: 5)),
      skip: 'Wait for first plugin to be published',
    );

    test(
      'with git source',
      () async {
        final dashProcess = await startDashProcess([
          'plugins',
          'install',
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
      skip: 'Wait for first plugin to be published',
    );

    test(
      'with local source',
      () async {
        // DartScript.self.pathToScriptDirectory has a bug and returns
        // /Users/pepe/dev/repos/sidekick/sidekick/async
        // instead of
        // /Users/pepe/dev/repos/sidekick/sidekick
        // so I have to parse the correct path
        final sidekickPath = RegExp(r'(^.*[/\\]sidekick[/\\]sidekick)')
            .matchAsPrefix(DartScript.self.pathToScriptDirectory)!
            .group(1)!;

        final pluginPath = Directory(sidekickPath)
            .directory('test/templates/minimal_sidekick_plugin')
            .path;

        final dashProcess = await startDashProcess([
          'plugins',
          'install',
          '--source',
          'path',
          pluginPath,
        ]);
        printOnFailure(await dashProcess.stdoutStream().join('\n'));
        printOnFailure(await dashProcess.stderrStream().join('\n'));
        dashProcess.shouldExit(0);

        final pluginProcess = await startDashProcess(
          ['minimal-sidekick-plugin'],
        );
        printOnFailure(await pluginProcess.stdoutStream().join('\n'));
        printOnFailure(await pluginProcess.stderrStream().join('\n'));
        pluginProcess.shouldExit(0);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}
