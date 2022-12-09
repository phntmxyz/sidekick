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
    final cli = await buildSidekickCli();
    final process = await cli.run(
      ['init', '-n', 'dashi'],
      workingDirectory: projectRoot,
    );
    await process.shouldExit(0);
    entrypoint = File("${projectRoot.path}/dashi");
    expect(entrypoint.existsSync(), isTrue);

    overrideSidekickCoreWithLocalPath(
      projectRoot.directory('packages/dashi_sidekick'),
    );
  });

  group('plugins install executes fine', () {
    setUp(() {
      printOnFailure(
        'Did you forget to update the max parameter '
        'of supportedInstallerVersions in install_plugin_command.dart '
        'to the next breaking version of sidekick_plugin_installer? ',
      );
    });

    test(
      'with default hosted source',
      () async {
        await runDashProcess([
          'sidekick',
          'plugins',
          'install',
          'sidekick_vault',
        ]);
        await runDashProcess(['vault', '-h']);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'with custom hosted source and version constraint',
      () async {
        await runDashProcess([
          'sidekick',
          'plugins',
          'install',
          '--hosted-url',
          'https://pub.flutter-io.cn/',
          'sidekick_vault',
          '>=0.6.0 <1.0.0'
        ]);
        await runDashProcess(['vault', '-h']);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    // TODO add similar test where --git-ref and --git-path are also used
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

        // without this, `git commit` crashes on CI
        'git config user.email "foo@bar.test"'.start(workingDirectory: pluginDir.path);
        'git config user.name "Foo Bar"'.start(workingDirectory: pluginDir.path);

        'git init'.start(workingDirectory: pluginDir.path);
        'git add .'.start(workingDirectory: pluginDir.path);
        'git commit -m "initial"'.start(workingDirectory: pluginDir.path);
        // Using `file://<path>` is required to mimick a remote repository more closely
        // Otherwise, `git clone --depth 1` behaves differently: --depth is ignored in local clones; use file:// instead
        final gitUrl = 'file://${pluginDir.absolute.path}';

        await runDashProcess([
          'sidekick',
          'plugins',
          'install',
          '--source',
          'git',
          gitUrl,
        ]);
        await runDashProcess(['minimal-sidekick-plugin']);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'with local source',
      () async {
        final pluginPath = Directory('test/templates/minimal_sidekick_plugin');

        await runDashProcess([
          'sidekick',
          'plugins',
          'install',
          '--source',
          'path',
          pluginPath.absolute.path,
        ]);

        await runDashProcess(['minimal-sidekick-plugin']);
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });

  for (final template in CreatePluginCommand.templates.keys) {
    test('plugin template $template generates valid plugin code', () async {
      await runDashProcess([
        'sidekick',
        'plugins',
        'create',
        '-t',
        template,
        '-n',
        'generated_plugin',
        projectRoot.path,
      ]);

      final pluginDir = projectRoot.directory('generated_plugin');
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
  }

  for (final template in CreatePluginCommand.templates.keys) {
    test(
      'plugin e2e $template: create, install, run',
      () async {
        await runDashProcess([
          'sidekick',
          'plugins',
          'create',
          '-t',
          template,
          '-n',
          template.snakeCase,
        ]);
        overrideSidekickCoreWithLocalPath(
          projectRoot.directory(template.snakeCase),
        );
        overrideSidekickPluginInstallerWithLocalPath(
          projectRoot.directory(template.snakeCase),
        );

        await runDashProcess(
          [
            'sidekick',
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

  /// This test uses the global sidekick CLI while the previous tests
  /// first generate a custom sidekick CLI and then use that
  test(
    'create plugin with global sidekick',
    () async {
      final tempDir = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final cli = await buildSidekickCli();
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
