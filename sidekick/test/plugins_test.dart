import 'package:dcli/dcli.dart';
import 'package:recase/recase.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/plugins/create_plugin_command.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';
import 'package:test_process/test_process.dart';

import 'templates/templates.dart';
import 'util/cli_runner.dart';

void main() {
  tearDownAll(tearDownSidekickCache);

  group('plugins install executes fine', () {
    test(
      'with default hosted source',
      () async {
        await withSidekickCli((cli) async {
          await cli.run([
            'sidekick',
            'plugins',
            'install',
            'sidekick_vault',
          ]);
        });
      },
      timeout: const Timeout(Duration(minutes: 5)),
      skip: 'Wait for first plugin to be published',
    );

    test(
      'with custom hosted source',
      () async {
        await withSidekickCli((cli) async {
          await cli.run([
            'sidekick',
            'plugins',
            'install',
            '--hosted-url',
            'https://pub.flutter-io.cn/',
            'sidekick_vault',
          ]);
        });
      },
      timeout: const Timeout(Duration(minutes: 5)),
      skip: 'Wait for first plugin to be published',
    );

    test(
      'with git source',
      () async {
        await withSidekickCli((cli) async {
          await cli.run([
            'sidekick',
            'plugins',
            'install',
            '--source',
            'git',
            '--git-path',
            'packages/umbra_cli',
            'https://github.com/wolfenrain/umbra',
          ]);
        });
      },
      timeout: const Timeout(Duration(minutes: 5)),
      skip: 'Wait for first plugin to be published',
    );

    test(
      'with local source',
      () async {
        printOnFailure(
          'Did you forget to update the max parameter of supportedInstallerVersions in install_plugin_command.dart to the next breaking version of sidekick_plugin_installer? ',
        );

        await withSidekickCli((cli) async {
          final pluginPath =
              Directory('test/templates/minimal_sidekick_plugin');
          await cli.run([
            'sidekick',
            'plugins',
            'install',
            '--source',
            'path',
            pluginPath.absolute.path,
          ]);

          await cli.run(
            ['minimal-sidekick-plugin'],
          );
        });
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });

  for (final template in CreatePluginCommand.templates.keys) {
    test('plugin template $template generates valid plugin code', () async {
      await withSidekickCli((cli) async {
        await cli.run([
          'sidekick',
          'plugins',
          'create',
          '-t',
          template,
          '-n',
          'generated_plugin',
        ]);

        final pluginDir = cli.root.directory('generated_plugin');
        final pluginPath = pluginDir.path;
        // override dependency, otherwise `dart analyze` fails when plugin uses unpublished API
        overrideSidekickPluginInstallerWithLocalPath(pluginDir);

        if (analyzeGeneratedCode) {
          overrideSidekickPluginInstallerWithLocalPath(pluginDir);
          run('dart pub get', workingDirectory: pluginPath);
          run('dart analyze --fatal-infos', workingDirectory: pluginPath);
          run('dart format --set-exit-if-changed $pluginPath');
        }

        expect(
          pluginDir.file('analysis_options.yaml').readAsStringSync(),
          contains('package:lint/analysis_options.yaml'),
        );
        expect(
          pluginDir.file('.gitignore').readAsStringSync(),
          contains('\npubspec.lock'),
        );

        expect(
          pluginDir.file('README.md').readAsStringSync(),
          allOf([
            contains('dashi sidekick plugins install'),
            contains('generated_plugin sidekick plugin'),
          ]),
        );
      });
    });
  }

  for (final template in CreatePluginCommand.templates.keys) {
    test(
      'plugin e2e $template: create, install, run',
      () async {
        await withSidekickCli((cli) async {
          await cli.run([
            'sidekick',
            'plugins',
            'create',
            '-t',
            template,
            '-n',
            template.snakeCase,
          ]);
          overrideSidekickCoreWithLocalPath(
            cli.root.directory(template.snakeCase),
          );
          overrideSidekickPluginInstallerWithLocalPath(
            cli.root.directory(template.snakeCase),
          );

          await cli.run(
            [
              'sidekick',
              'plugins',
              'install',
              '-s',
              'path',
              template.snakeCase,
            ],
          );

          await cli.run(
            [template.paramCase],
          );
        });
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  }

  /// This test uses the global sidekick CLI while the previous tests
  /// first generate a custom sidekick CLI and then use that
  test(
    'create plugin with global sidekick',
    () async {
      final tempDir = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final cli = cachedSidekickExecutable;
      final process = await cli.run(
        [
          'plugins',
          'create',
          '-t',
          'install-only',
          '-n',
          'install_only_plugin',
        ],
        workingDirectory: tempDir,
      );
      process.stdoutStream().listen(print);
      process.stderrStream().listen(print);
      await process.shouldExit(0);

      final pluginPath = tempDir.directory('install_only_plugin').path;
      run('dart pub get', workingDirectory: pluginPath);
      if (analyzeGeneratedCode) {
        run('dart analyze --fatal-infos', workingDirectory: pluginPath);
        run('dart format --set-exit-if-changed $pluginPath');
      }
    },
  );
}
