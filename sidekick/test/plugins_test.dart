import 'package:dcli/dcli.dart';
import 'package:recase/recase.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/plugins/create_plugin_command.dart';
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
      ['init', '-n', 'dashi'],
      workingDirectory: projectRoot,
    );
    await process.shouldExit(0);
    entrypoint = File("${projectRoot.path}/dashi");
    expect(entrypoint.existsSync(), isTrue);

    if (shouldUseLocalDevs) {
      overrideSidekickCoreWithLocalPath(
        projectRoot.directory('packages/dashi_sidekick'),
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
        final pluginPath = Directory('test/templates/minimal_sidekick_plugin');

        await runDashProcess([
          'plugins',
          'install',
          '--source',
          'path',
          pluginPath.absolute.path,
        ]);

        await runDashProcess(
          ['minimal-sidekick-plugin'],
        );
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });

  for (final template in CreatePluginCommand.templates.keys) {
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

      final pluginDir = projectRoot.directory('generated_plugin');
      final pluginPath = pluginDir.path;

      run('dart pub get', workingDirectory: pluginPath);
      run('dart analyze --fatal-infos', workingDirectory: pluginPath);
      run('dart format --set-exit-if-changed $pluginPath');

      expect(
        pluginDir.file('analysis_options.yaml').readAsStringSync(),
        _expectedAnalysisOptions,
      );
      expect(
        pluginDir.file('.gitignore').readAsStringSync(),
        _expectedGitignore,
      );
      expect(
        pluginDir.file('README.md').readAsStringSync(),
        _getExpectedReadme(template),
      );
    });
  }

  for (final template in CreatePluginCommand.templates.keys) {
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

  /// This test uses the global sidekick CLI while the previous tests
  /// first generate a custom sidekick CLI and then use that
  test(
    'create plugin with global sidekick',
    () async {
      final tempDir = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final process = await sidekickCli(
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
      run('dart analyze --fatal-infos', workingDirectory: pluginPath);
      run('dart format --set-exit-if-changed $pluginPath');
    },
    skip: 'Wait for sidekick_core 0.9.1 to be published',
  );
}

const _expectedAnalysisOptions = '''
include: package:lint/analysis_options.yaml

linter:
  rules:
    avoid_print: false

''';

const _expectedGitignore = '''
# Files and directories created by pub.
.dart_tool/
.packages

# Conventional directory for build outputs.
build/

# Omit committing pubspec.lock for library packages; see
# https://dart.dev/guides/libraries/private-files#pubspeclock.
pubspec.lock
''';

String _getExpectedReadme(String templateType) => '''
# generated_plugin sidekick plugin

A plugin for [sidekick CLIs](https://pub.dev/packages/sidekick).  
Generated from template `$templateType`.

## Description

[sidekick](https://pub.dev/packages/sidekick) generates custom command line apps for automating tasks.  
Plugins encapsulate certain tasks and can be used to easily extend the capabilities of a sidekick CLI.

Take a look at the available [sidekick plugins on pub.dev](https://pub.dev/packages?q=dependency%3Asidekick_core).


## Installation

### Prerequisites:

- install `sidekick`: `dart pub global activate sidekick`
- generate custom sidekick CLI: `sidekick init`

Installing plugins to a custom sidekick CLI is very similar to installing a package with
the [pub tool](https://dart.dev/tools/pub/cmd/pub-global#activating-a-package).

### Installing a plugin from a pub server

```bash
dashi plugins install <plugin name on pub server, e.g. sidekick_vault>
```

By default, [pub.dev](https://pub.dev) is used as pub server. A custom pub server can be used with the `--hosted-url`
parameter.

### Installing a plugin from a git repository

```bash
dashi plugins install --source git <link to git repository>
```

#### Optional parameters:

- `--git-ref`: Git branch name, tag or full commit SHA (40 characters) to be installed
- `--git-path`: Path of git package in repository (use when repository root contains multiple packages)
  - e.g. `dashi plugins install --source git --git-path sidekick_vault https://github.com/phntmxyz/sidekick`

### Installing a plugin from a local path

```bash
dashi plugins install --source path <path to plugin on local machine>
```

## Developing plugins

### Plugin templates

A plugin template can be generated with `sidekick plugins create --template <template type> --name <plugin name>`.

This plugin was generated from the template `$templateType`.

The `--template` parameter must be given one of the following values:

- `install-only`  
  This template is the very minimum, featuring just a `tool/install.dart` file
  that writes all code to be installed into the users sidekick CLI.

  It doesn't add a pub dependency with shared code. All code is generated in
  the users sidekick CLI, being fully adjustable.


- `shared-command`  
  This template adds a pub dependency to a shared CLI `Command` and registers
  it in the user's sidekick CLI.

  This method is designed for cases where the command might be configurable
  with parameters but doesn't allow users to actually change the code.

  It allows updates (via `pub upgrade`) without users having to touch their code.


- `shared-code`  
  This template adds a pub dependency and writes the code of a `Command` into
  the user's sidekick CLI as well as registers it there.
 
  The `Command` code is not shared, thus is highly customizable. But it uses
  shared code from the plugin package that is registered added as dependency.
  Update of the helper functions is possible via pub, but the actual command
  flow is up to the user.

### Implementing functionality

Every plugin needs a `tool/install.dart` file which is executed by the `dashi plugins install` command.
This adds the plugin command to the custom sidekick CLI which is then available as 
`dashi <plugin-name>` (i.e. `dashi generated-plugin`).  

The plugin needs to be implemented in the generated `Command` class (i.e. `GeneratedPluginCommand`).

Use the `argParser` attribute in the constructor to add parameters or subcommands (e.g. `argParser.addOption(...)`).

Implement the functionality in the `run` method of the command. Here following helpers are accessible:
- Execute Dart and Flutter commands with the `dart` and `flutter` functions.  
  The Dart runtime bundled with the custom sidekick CLI is accesible through `sidekickDartRuntime.dart`.
- Use the generated `<your sidekick CLI name>Project` variable to access other packages.
''';
