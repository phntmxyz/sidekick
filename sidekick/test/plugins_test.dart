import 'package:dcli/dcli.dart';
import 'package:recase/recase.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/plugins/create_plugin_command.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

import 'templates/templates.dart';
import 'util/cli_runner.dart';

void main() {
  group('plugins install executes fine', () {
    setUp(() {
      printOnFailure(
        'Did you forget to update the max parameter '
        'of supportedInstallerVersions in install_plugin_command.dart '
        'to the next breaking version of sidekick_plugin_installer? ',
      );
    });

    test(
      'with custom hosted source and version constraint',
      () async {
        await withSidekickCli((cli) async {
          await cli.run([
            'sidekick',
            'plugins',
            'install',
            '--hosted-url',
            'https://pub.flutter-io.cn/',
            'sidekick_vault',
            '>=1.0.0 <2.0.0',
          ]);
        });
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    // TODO adapt this test to use --git-ref and --git-path as well
    // to do this the Dart SDK version of the `dash` sidekick CLI needs to be
    // updated. It currently is using Dart 2.14 which neither contains
    // support for `--git-ref` nor `--git-path` in `pub global activate`.
    // `--git-path` is supported in today's Dart 2.18, but support for
    // `--git-ref` will probably only be available from Dart 2.19
    // once https://github.com/dart-lang/pub/pull/3656 is deployed
    test(
      'with git source',
      () async {
        // TODO: this is a workaround because there currently is no published
        // sidekick plugin which is installable with Dart 2.14 (the dash
        // sidekick CLI has sidekickDartRuntime @ Dart 2.14)
        final pluginDir =
            setupTemplateProject('test/templates/minimal_sidekick_plugin');

        'git init'.start(workingDirectory: pluginDir.path);
        'git add .'.start(workingDirectory: pluginDir.path);
        await withEnvironment(
          () async =>
              'git commit -m "initial"'.start(workingDirectory: pluginDir.path),
          // without this, `git commit` crashes on CI
          environment: {
            'GIT_AUTHOR_NAME': 'Sidekick Test CI',
            'GIT_AUTHOR_EMAIL': 'sidekick-ci@phntm.xyz',
            'GIT_COMMITTER_NAME': 'Sidekick Test CI',
            'GIT_COMMITTER_EMAIL': 'sidekick-ci@phntm.xyz',
          },
        );
        // Using `file://<path>` is required to mimick a remote repository more closely
        // Otherwise, `git clone --depth 1` behaves differently: --depth is ignored in local clones; use file:// instead
        final gitUrl = 'file://${pluginDir.absolute.path}';

        await withSidekickCli((cli) async {
          await cli.run([
            'sidekick',
            'plugins',
            'install',
            '--source',
            'git',
            gitUrl,
          ]);
        });
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });

  group('create plugin, install in cli, run plugin command', () {
    for (final pluginName in ['foo', 'sidekick_foo_bar_sidekick_plugin']) {
      for (final template in CreatePluginCommand.templates.keys) {
        test(
          "template '$template', plugin name '$pluginName'",
          () async {
            await withSidekickCli((cli) async {
              // create plugin
              await cli.run([
                'sidekick',
                'plugins',
                'create',
                '-t',
                template,
                '-n',
                pluginName,
              ]);

              final pluginDir = cli.root.directory(pluginName);
              overrideSidekickCoreWithLocalPath(pluginDir);
              overrideSidekickPluginInstallerWithLocalPath(pluginDir);

              // plugin code should be valid
              if (analyzeGeneratedCode) {
                run('dart pub get', workingDirectory: pluginDir.path);
                run(
                  'dart analyze --fatal-infos',
                  workingDirectory: pluginDir.path,
                );
                run('dart format --set-exit-if-changed ${pluginDir.path}');
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
                  contains('$pluginName sidekick plugin'),
                ]),
              );

              // plugin can be installed
              await cli.run(
                [
                  'sidekick',
                  'plugins',
                  'install',
                  '-s',
                  'path',
                  pluginName,
                ],
              );

              // TODO if we add an option to execute the sidekick entrypoint without compiling it, we could speed up the tests a little bit here:
              // after a plugin is installed, the hash values of the sidekick CLI
              // change and thus the entrypoint has to be recompiled.
              // however in this case, we don't gain anything time-wise from compiling
              // because we use the entrypoint only once here.
              // so if we ran the entrypoint without compiling it heree, these tests
              // would be a little bit faster.

              // running the new command should succeed
              final command = pluginName
                  .removePrefix('sidekick_')
                  .removePrefix('plugin_')
                  .removeSuffix('_plugin')
                  .removeSuffix('_sidekick')
                  .paramCase;
              await cli.run([command]);
            });
          },
          timeout: const Timeout(Duration(minutes: 5)),
        );
      }
    }
  });
}
