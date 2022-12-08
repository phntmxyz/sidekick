# Sidekick

Dart CLI generator for Flutter and Dart apps - extend your project with custom tasks, add a sidekick to your app.

Write your automation scripts in Dart - a language all your coworkers are comfortable with - while fully supporting debugging and testing without losing the simplicity of executing shell scripts.

Awesome examples

- Deployment scripts with multi-dimension build flavors
- Bump the version of your packages at once
- Generate release notes by combining merged PRs and completed JIRA issues
- Fix broken generated build_runner code while waiting for a fix to be merged
- Update GraphQL schemas
- Create init scripts for coworkers to set up their environment

## Getting Started

### Create your first CLI

Install the CLI generator `sidekick`. This is only required for generation, not for the execution of the CLI.

```bash
dart pub global activate sidekick
```

Initialize project

```bash
sidekick init <path-to-repo> 
```

Follow the instructions and you just created your first sidekick CLI.
You can execute your CLI right away using its entrypoint and use any of the existing tasks.

Assuming your CLI is called `flg` (short for `flutter gallery`), execute the `flg` shell script in the root of your repository.

```bash
$ ./flg

A sidekick CLI to equip Dart/Flutter projects with custom tasks

Usage: flg <command> [arguments]

Global options:
-h, --help    Print this usage information.

Available commands:
  analyze          Dart analyzes the whole project
  clean            Cleans the project
  dart             Calls dart
  deps             Gets dependencies for all packages
  flutter          Call the Flutter SDK associated with the project
  sidekick         Manages the sidekick CLI

Run "flg help <command>" for more information about a command.
```

## Plugins

### Our Favorite Plugins

| Plugin                                                                          | Description                                                       |
|---------------------------------------------------------------------------------|-------------------------------------------------------------------|
| [sidekick_vault](https://pub.dev/packages/sidekick_vault)                       | Store project secrets encrypted in your repository                |
| [dockerize_sidekick_plugin](https://pub.dev/packages/dockerize_sidekick_plugin) | Wrap your Flutter Web App in a docker container                   |
| [flutterw_sidekick_plugin](https://pub.dev/packages/flutterw_sidekick_plugin)   | Pin a Flutter version to your project and share it with your team |

See the [full list of available plugins](https://pub.dev/packages?q=dependency%3Asidekick_plugin_installer)

To write your own plugin checkout the [docs](#sidekick-plugins-install).

### Install plugin

To install more command, you can use install plugins with 

```bash
$ <cli> sidekick plugins install <pub-package>
```


## Preinstalled commands

### analyze

Runs the analyzer for all packages in the project.

### dart

Runs the bundled `dart` runtime with any arguments. 
By calling `flg dart` you make sure to always use the correct dart version anyone else in your project is using.

### clean

Deletes the build directory of the main application.
This commands code is part of your CLI, intended to be modified to your needs.

### deps

Gets all dependencies for all packages in your project.
This will become your most used command in no time!

### flutter

Runs the bundled `flutter` runtime (provided via [flutter-wrapper](https://github.com/passsy/flutter_wrapper)) with any arguments.
By calling `flg flutter` you make sure to always use the correct flutter version, like anyone else of your team.

### sidekick install-global

You can execute your CLI from anywhere. To do so, run the `install-global` command and follow the instructions.

```bash
$ ./flg sidekick install-global

Please add $HOME/.sidekick/bin to your PATH. 
Add this to your shell's config file (.zshrc, .bashrc, .bash_profile, ...)

  export PATH="$PATH":"$HOME/.sidekick/bin"

Then, restart your terminal
```

After adjusting your PATH, you can execute the CLI from anywhere.

```bash
$ flg
```

### sidekick plugins create

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

### sidekick plugins install

#### Installing a plugin from a pub server

```bash
<cli> sidekick plugins install <plugin name on pub server, e.g. sidekick_vault>
```

By default, [pub.dev](https://pub.dev) is used as pub server. A custom pub server can be used with the `--hosted-url`
parameter.

#### Installing a plugin from a git repository

```bash
<cli> sidekick plugins install --source git <link to git repository>
```

**Optional parameters:**

- `--git-ref`: Git branch name, tag or full commit SHA (40 characters) to be installed
- `--git-path`: Path of git package in repository (use when repository root contains multiple packages)
    - e.g. `${cliNameOrNull ?? 'your_custom_sidekick_cli'} sidekick plugins install --source git --git-path sidekick_vault https://github.com/phntmxyz/sidekick`

#### Installing a plugin from a local path

```bash
<cli> sidekick plugins install --source path <path to plugin on local machine>
```

### recompile

The entrypoint usually automatically detects when you changed the source code of your CLI. 
But for rare cases (like [path dependencies](https://dart.dev/tools/pub/dependencies#path-packages)) it is not possible to detect changes.
In those scenarios use `flg recompile` to force recompile your CLI.

## Writing custom tasks (Commands)

Writing your own commands is done in two steps.

1. Create a class for your new command, give it a `name`.

  ```dart
  import 'package:sidekick_core/sidekick_core.dart';
  
  class YourCommand extends Command {
    @override
    String get description => 'does foo';
  
    @override
    String get name => 'foo';
    
    @override
    Future<void> run() async {
      // your custom code here
    }
  }
  ```

2. Register your new command in the `packages/flg_sidekick/lib/flg_sidekick.dart` file by adding it to the runner

  ```dart
  // Generated by `sidekick init`
  Future<void> runFlg(List<String> args) async {
    final runner = initializeSidekick(name: 'flg', mainProjectPath: '.');
  
    flgProject = FlgProject(mainProject.root);
  
    runner
      ..addCommand(FlutterCommand())
      //.. more commands
      ..addCommand(InstallGlobalCommand())
      ..addCommand(YourCommand()); // <-- Register your own command
  
    //...
  ```

### Handling arguments

The sidekick CLI is based on [package:args](https://pub.dev/packages/args).
Use the existing `argParser` of `Command` to define and parse the arguments of your command.

```dart
class EchoTextCommand extends Command {
  @override
  String get name => 'echo-text';

  @override
  String get description => 'Echos the text';

  EchoTextCommand() {
    argParser.addOption('text');
  }

  @override
  Future<void> run() async {
    final cliName = argResults!['text'] as String?;
    print('echo $cliName');
  }
}
```

```dart
$ flg echo-text --text="Hello World"
Hello World
```

## Motivation

Once you start automating your development workflow, you rather soon hit the limits of Bash.
Not only is it hard to learn for newcomers, but also hard to understand for experienced developers.
The lack of dependency management and JSON parsing are only a [few reasons](https://mywiki.wooledge.org/BashWeaknesses) that rule it out as a usable scripting language.

Build systems like [Gradle](https://gradle.org/) allow you to write your tasks.
But Dart and Flutter projects are not compatible with Gradle and don't offer an easy way to add custom tasks.

While you can place your dart scripts in `/tool` and add `dev_dependencies` to your `pubspec.yaml` you might rather soon run into version conflicts between your app and your scripts.

Let's face it, you need a standalone dart project for your custom CLI, and sidekick does the heavy lifting for you.

## Principals

The sidekick CLI is **self-executable**

- Executing the CLI requires no extra dependencies. The entrypoint can be executed as shell script. That makes it easy to use on CI/CD servers.
- By calling the `entrypoint` shell script, it automatically downloads a (pinned) Dart runtime and compiles the CLI project.
- Self-executable and self-contained. Dependencies are not shared with the app.

Full control of the source code

- Changing existing code doesn't require a PR to the sidekick project. You can **customize the generated commands** to your liking.
- There is no program between your CLI and the Dart compiler that reads, alters, wraps or breaks your code.
- You don't like how the CLI handles errors or prints the help page? You can change that, you have full control

Being able to use all the benefits of a modern language

- Like any pure Dart program, the sidekick CLI can be executed with a **debugger**. No need for print statements!
- Full **IDE support** and syntax highlighting
- Full **testing** support. Who doesn't want unit tests for their custom tasks?

## Development

### Install cli locally during development

That's useful when you want to test the sidekick cli during development on your machine. Tests are great, but sometimes you want to see the beast in action.

```bash
cd sidekick
dart pub global activate -s path .
```

## License

```text
Copyright 2021 phntm GmbH

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
