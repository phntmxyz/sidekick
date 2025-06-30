# Changelog

## [3.0.0](https://github.com/phntmxyz/sidekick/compare/sidekick-v2.1.0..sidekick-v3.0.0) (2025-6-30)

- Support for Dart 3.5

## [2.1.0](https://github.com/phntmxyz/sidekick/compare/sidekick-v2.0.2..sidekick-v2.1.0) (2023-9-26)

- **NEW:** Added tab completion [#245](https://github.com/phntmxyz/sidekick/pull/245) https://github.com/phntmxyz/sidekick/commit/dd7b18f07dd792ed9fd3c3a37bc73f254aa807c9
- Updated README https://github.com/phntmxyz/sidekick/commit/48f58c0b883dab552181b9d25165bdfc05006136
- Fixed bug in `shared-command` plugin template when plugin name ends with `_sidekick_plugin` [#242](https://github.com/phntmxyz/sidekick/pull/242) https://github.com/phntmxyz/sidekick/commit/4d681a62a7df9514e3a9e4b5e903736842b242e7

## [2.0.2](https://github.com/phntmxyz/sidekick/compare/sidekick-v2.0.1..sidekick-v2.0.2) (2023-7-2)

- Use `sidekick_core` version with fix for dcli/pubspec2 dependency problem [#236](https://github.com/phntmxyz/sidekick/pull/236) https://github.com/phntmxyz/sidekick/commit/a20ce751298cea41c5ced495026e737dac0c8c93

## [2.0.1](https://github.com/phntmxyz/sidekick/compare/sidekick-v2.0.0..sidekick-v2.0.1) (2023-7-2)

- Release with locked dependencies so installation is stable
- Use new templates from [`sidekick_core`](https://github.com/phntmxyz/sidekick/commit/854b943d5f42bbfbfa6426a7a9ebde02311c4a2a)

## [2.0.0](https://github.com/phntmxyz/sidekick/compare/sidekick-v1.0.1..sidekick-v2.0.0) (2023-6-5)

- Dart 3 support

## [1.0.1](https://github.com/phntmxyz/sidekick/compare/sidekick-v1.0.0..sidekick-v1.0.1) (2023-5-11)

- Add topics to `pubspec.yaml`.

## [1.0.0](https://github.com/phntmxyz/sidekick/compare/sidekick-v0.10.0..sidekick-v1.0.0) (2023-1-30)

- Update to `sidekick_core: ^1.0.0` [#214](https://github.com/phntmxyz/sidekick/pull/214)
- Does not create a git repo `git init` anymore [#219](https://github.com/phntmxyz/sidekick/pull/219)
- No absolute path required for `projectRoot`. It's now relative to working directory [#219](https://github.com/phntmxyz/sidekick/pull/219)
- Creates empty folder when `projectRoot` doesn't exist (Fixes [#205](https://github.com/phntmxyz/sidekick/issues/205)) [#219](https://github.com/phntmxyz/sidekick/pull/219)
- Rename option `entrypointDirectory` -> `projectRoot` [#219](https://github.com/phntmxyz/sidekick/pull/219)
- Install flutterw using [flutterw_sidekick_plugin](https://github.com/passsy/flutterw_sidekick_plugin) when a flutter package is detected [#219](https://github.com/phntmxyz/sidekick/pull/219)

## [0.10.0](https://github.com/phntmxyz/sidekick/compare/sidekick-v0.9.0..sidekick-v0.10.0) (2023-1-25)

- Update to `sidekick_core: 1.0.0` [#214](https://github.com/phntmxyz/sidekick/pull/214)
- Default to Dart `2.18.6` for new CLIs [#195](https://github.com/phntmxyz/sidekick/pull/195)
- Lock dependencies with correct lower bound [#215](https://github.com/phntmxyz/sidekick/pull/215)

## [0.9.0](https://github.com/phntmxyz/sidekick/compare/sidekick-v0.8.0..sidekick-v0.9.0) (2023-1-20)

## Updates to the sidekick CLI

- `sidekick update` now updates the global sidekick CLI to the latest version [#159](https://github.com/phntmxyz/sidekick/pull/159)

## Updates from sidekick_core (0.13.1 -> 0.15.1)

### Changes to generated sidekick CLIs

- `<cli> <command>` Sidekick CLIs now automatically check for updates after executing a command. Disable with `export SIDEKICK_ENABLE_UPDATE_CHECK=false` [#177](https://github.com/phntmxyz/sidekick/pull/177) [#171](https://github.com/phntmxyz/sidekick/pull/171)
- `<cli> sidekick update` now updates to the latest stable Dart SDK [#167](https://github.com/phntmxyz/sidekick/pull/167)
- Automatic `pub upgrade` when CLI compilation fails (due to Dart SDK upgrade) [#166](https://github.com/phntmxyz/sidekick/pull/166)

### New APIs

- New: `BashCommand` to simplify converting bash scripts to commands in dart [#168](https://github.com/phntmxyz/sidekick/pull/168)

    ```dart
    BashCommand(
      name: 'codegen',
      description: 'Runs build runner',
      workingDirectory: runner.mainProject?.root,
      script: () => '''
    ${systemFlutterSdkPath()}/bin/flutter pub run build_runner build --delete-conflicting-outputs
    ''',
    ),
    ```

### Bugfixes and improvements

- `DepsCommand` now ignores sidekick packages, which pull deps automatically with embedded Dart SDK [#184](https://github.com/phntmxyz/sidekick/pull/184)
- Fix: `DepsCommand.excludeGlob` now starts matching at repo root, not CWD [#183](https://github.com/phntmxyz/sidekick/pull/183)
- `sidekick update` now handles `path` and `git` dependencies when updating `sidekick_core` [#180](https://github.com/phntmxyz/sidekick/pull/180)
- `DartPackage.fromDirectory()` Simplify detection of Flutter packages [#182](https://github.com/phntmxyz/sidekick/pull/182)

### Template Changes

- CLI template now does **not** generate a `<cli>_project.dart` file. You can continue to use yours but we found most people didn't need it. ([#156](https://github.com/phntmxyz/sidekick/pull/156))
- UsageException is now correctly printed ([#157](https://github.com/phntmxyz/sidekick/pull/157)) (with `<cli> sidekick update` migration)
- Calling the CLI with zero arguments now also checks for sidekick updates ([#157](https://github.com/phntmxyz/sidekick/pull/157)) (with `<cli> sidekick update` migration)
- Fix unnecessary CLI recompilation in `run.sh` ([#152](https://github.com/phntmxyz/sidekick/pull/152))

### API Changes

- New `DartPackage.lockfile` getter ([#159](https://github.com/phntmxyz/sidekick/pull/159))
- New `DartPackage.fromArgResults` constructor for Commands that take a package as only argument. Parses `rest` and `cwd`. ([#160](https://github.com/phntmxyz/sidekick/pull/160))
- `SidekickTemplateProperties` now has optional properties. Caller has to decide what to inject for each template. ([#161](https://github.com/phntmxyz/sidekick/pull/161))

## 0.8.0
- `sidekick --version` now prints the version

### sidekick init
- cli entrypoint location (`--entrypointDirectory`) and cli package location (`--cliPackageDirectory `) are now individually configurable. Will be asked during `init` if not provided.
- Allow project names with underscores #112

- Cli template updates
  - New `<cli> sidekick update` command (available since `sidekick_core: 0.13.0`), to update your existing sidekick cli to the latest version, like running `sidekick init` again #111
  - Output when compiling the cli is now reduced (no pub get output) #109
  - Analyzer now ignores the cli `build` dir #107

### sidekick plugins
- Updated plugin templates
  - Using new `addSelfAsDependency()` method
  - `shared-code` template now saves the template dart files in the `template` dir, not as plain string in code. #132

## 0.7.2

- Add documentation
- Add example folder
- Update repository link

## 0.7.1

- Hotfix of build error

## 0.7.0

- New plugins system which can be used to easily extend your sidekick CLI and share automation with others (#58)
- `sidekick plugins create` creates a plugin from a template (#65, #79, #91)
- `sidekick` command in generated sidekick CLIs now bundles plugins, recompile, and install-global command (#82, #89)
- Add validation to only allow CLI names which are not already occupied on PATH (#76)
- Add `CleanCommand` to CLI template (#85)
- sidekick CLIs now download their own bundled Dart SDK instead of using `flutterw` (#53)

## 0.6.0

- We now support the "multiple packages" repository layout where all packages are located in `/packages`
- For multi package layouts, use the `--mainProjectPath` option to specify the path to the `mainProject`
- Fix macos detection in `run.sh` script
- The entrypoint is now executable on Unix systems when sidekick was generated on Windows [#23](https://github.com/phntmxyz/sidekick/pull/23)
- the mason cli is now pinned in the project to be used in `/tools`

## 0.5.0

- Naming is hard, we're now suggesting cli names
- Update `sidekick_core` dependency on init
- Generate `.gitignore`

## 0.4.0

- Automatic recompile when cli code changes
- New `install-global` command. This is now a manual step and works on M1 macs (Darwin-arm64)
- entrypoint has been simplified and is now just a symlink on steroids
- Remove dependency on `realpath` (which was a third-party tool on macos)
- The root project has now a valid name

## 0.3.0

- Windows support
- Better `cliName` missing error message

## 0.2.0

- Rename `update_sidekick` task to `recompile`
- Update `sidekick-core`
- Update `mason`
- Support for dart 2.12

## 0.1.1

Update `sidekick-core`

## 0.1.0

First working prototype of `sidekick init` using `flutterw`

## 0.0.1

Claim pub name for CLI
