import 'package:dcli/dcli.dart';
import 'package:recase/recase.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

import 'templates/templates.dart';
import 'util/cli_runner.dart';
import 'util/local_testing.dart';

void main() {
  late File entrypoint;
  late Directory projectRoot;

  Future<void> runDashProcess(Iterable<String> arguments) async {
    final process = await TestProcess.start(
      entrypoint.path,
      arguments,
      workingDirectory: projectRoot.path,
    );

    process.stdoutStream().listen(print);
    process.stderrStream().listen(print);
    await process.shouldExit(0);
  }

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
        await runDashProcess(['plugins', 'install', 'sidekick_vault']);
      },
      timeout: const Timeout(Duration(minutes: 5)),
      skip: 'Wait for first plugin to be published',
    );

    test(
      'with custom hosted source',
      () async {
        await runDashProcess([
          'plugins',
          'install',
          '--hosted-url',
          'https://pub.flutter-io.cn/',
          'sidekick_vault',
        ]);
      },
      timeout: const Timeout(Duration(minutes: 5)),
      skip: 'Wait for first plugin to be published',
    );

    test(
      'with git source',
      () async {
        await runDashProcess([
          'plugins',
          'install',
          '--source',
          'git',
          '--git-path',
          'packages/umbra_cli',
          'https://github.com/wolfenrain/umbra',
        ]);
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

        await runDashProcess([
          'plugins',
          'install',
          '--source',
          'path',
          pluginPath,
        ]);

        await runDashProcess(
          ['minimal-sidekick-plugin'],
        );
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });

  // TODO: use CreatePluginCommand.templates.keys instead (import 'package:sidekick_core/src/commands/plugins/create_plugin_command.dart';)
  const templates = [
    'install-only',
    'shared-command',
    'shared-code',
  ];

  for (final template in templates) {
    test('plugin template $template generates valid plugin code', () async {
      await runDashProcess([
        'plugins',
        'create',
        '-t',
        template,
        '-n',
        'generated_plugin',
        projectRoot.path,
      ]);

      final pluginPath = projectRoot.directory('generated_plugin').path;

      run('dart pub get', workingDirectory: pluginPath);
      run('dart analyze', workingDirectory: pluginPath);
      run('dart format --set-exit-if-changed $pluginPath');
    });
  }

  for (final template in templates) {
    test(
      'plugin e2e $template: create, install, run',
      () async {
        await runDashProcess([
          'plugins',
          'create',
          '-t',
          template,
          '-n',
          template.snakeCase,
        ]);

        await runDashProcess(
          [
            'plugins',
            'install',
            '-s',
            'path',
            template.snakeCase,
          ],
        );

        await runDashProcess(
          [template.paramCase],
        );
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  }
}
