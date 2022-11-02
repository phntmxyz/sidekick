import 'package:meta/meta.dart';
import 'package:recase/recase.dart';
import 'package:sidekick_core/sidekick_core.dart';

/// A file structure template that can be written to disk
abstract class PluginTemplateGenerator {
  const PluginTemplateGenerator();

  /// Generates the template and writes it to [PluginTemplateProperties.pluginDirectory]
  @mustCallSuper
  void generate(PluginTemplateProperties props) {
    props.pluginDirectory
        .file('analysis_options.yaml')
        .writeAsStringSync(props.analysisOptionsTemplate);

    props.pluginDirectory
        .file('.gitignore')
        .writeAsStringSync(props.gitignoreTemplate);

    props.pluginDirectory
        .file('README.md')
        .writeAsStringSync(props.readmeTemplate);
  }
}

class PluginTemplateProperties {
  /// The name of the to be generated plugin
  final String pluginName;

  /// The name of the command that will be generated
  String get commandName {
    return pluginName.replaceAll('_sidekick_plugin', '').paramCase;
  }

  /// Where the files should be written to. This is considered as root directory
  final Directory pluginDirectory;

  /// The type of template to generate. Also see [CreatePluginCommand.templates]
  final String templateType;

  const PluginTemplateProperties({
    required this.pluginName,
    required this.pluginDirectory,
    required this.templateType,
  });
}

extension on PluginTemplateProperties {
  String get analysisOptionsTemplate => '''
include: package:lint/analysis_options.yaml

linter:
  rules:
    avoid_print: false
''';

  String get gitignoreTemplate => '''
# Files and directories created by pub.
.dart_tool/
.packages

# Conventional directory for build outputs.
build/

# Omit committing pubspec.lock for library packages; see
# https://dart.dev/guides/libraries/private-files#pubspeclock.
pubspec.lock
''';

  String get readmeTemplate => '''
# $pluginName sidekick plugin

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
${cliNameOrNull ?? 'your_custom_sidekick_cli'} sidekick plugins install <plugin name on pub server, e.g. sidekick_vault>
```

By default, [pub.dev](https://pub.dev) is used as pub server. A custom pub server can be used with the `--hosted-url`
parameter.

### Installing a plugin from a git repository

```bash
${cliNameOrNull ?? 'your_custom_sidekick_cli'} sidekick plugins install --source git <link to git repository>
```

#### Optional parameters:

- `--git-ref`: Git branch name, tag or full commit SHA (40 characters) to be installed
- `--git-path`: Path of git package in repository (use when repository root contains multiple packages)
  - e.g. `${cliNameOrNull ?? 'your_custom_sidekick_cli'} sidekick plugins install --source git --git-path sidekick_vault https://github.com/phntmxyz/sidekick`

### Installing a plugin from a local path

```bash
${cliNameOrNull ?? 'your_custom_sidekick_cli'} sidekick plugins install --source path <path to plugin on local machine>
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

Every plugin needs a `tool/install.dart` file which is executed by the `${cliNameOrNull ?? 'your_custom_sidekick_cli'} sidekick plugins install` command.
This adds the plugin command to the custom sidekick CLI which is then available as 
`${cliNameOrNull ?? 'your_custom_sidekick_cli'} <plugin-name>` (i.e. `${cliNameOrNull ?? 'your_custom_sidekick_cli'} ${pluginName.paramCase}`).  

The plugin needs to be implemented in the generated `Command` class (i.e. `${pluginName.pascalCase}Command`).

Use the `argParser` attribute in the constructor to add parameters or subcommands (e.g. `argParser.addOption(...)`).

Implement the functionality in the `run` method of the command. Here following helpers are accessible:
- Execute Dart and Flutter commands with the `dart` and `flutter` functions.  
  The Dart runtime bundled with the custom sidekick CLI is accessible through `sidekickDartRuntime.dart`.
- Use the generated `<your sidekick CLI name>Project` variable to access other packages.
''';
}
