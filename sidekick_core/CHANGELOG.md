# Changelog

## [1.0.0](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v0.15.1..sidekick_core-v1.0.0) (2023-1-25)

### Breaking API & Behaviour Changes
- Sidekick CLIs now works without a git repository. The `projectRoot` is defined where the shell `entryPoint` is located.
- New `SidekickContext` with getters for `sidekickPackage`, `cliName`, `projectRoot`, `entryPoint` and `repository` [#178](https://github.com/phntmxyz/sidekick/pull/178)
- Deprecation of `Repository` and top-level `repository` [#178](https://github.com/phntmxyz/sidekick/pull/178)
- Behaviour: paths for `initializeSidekick()` are now relative to `projectRoot`, not `repository`. Sidekick will print warnings when you're using wrong paths [#178](https://github.com/phntmxyz/sidekick/pull/178)
- Removal of `git()`. It was unused. Since sidekick doesn't require git anymore it was removed. [#208](https://github.com/phntmxyz/sidekick/pull/208)
- Behaviour: `flutter` and `dart` throw by default when failing. Use `nothrow: true` to ignore errors (`exitCode != 0`) [#206](https://github.com/phntmxyz/sidekick/pull/206)
- Behaviour: `flutter` and `dart` default to `Directory.current`, not `entryWorkingDirectory` [#206](https://github.com/phntmxyz/sidekick/pull/206)
- Removal of `flutterw()`. `flutter` and `dart` do not fall back to `flutterw()`. It is now available as plugin https://github.com/passsy/flutterw_sidekick_plugin [#208](https://github.com/phntmxyz/sidekick/pull/208)
- Deprecate top-level `cliName`/`cliNameOrNull` in favor of `SidekickContext.cliName` [#208](https://github.com/phntmxyz/sidekick/pull/208)
- Deprecate `name` of `initializeSidekick()`. The name is now inferred from the `pubspec.yaml` from the package name (`<name>_sidekick`). [#209](https://github.com/phntmxyz/sidekick/pull/209)
- Deprecate `findRepository()` in favor of `SidekickContext.repository` or `SidekickContext.projectRoot` [#178](https://github.com/phntmxyz/sidekick/pull/178)
- Removal of `deinitializeSidekick()` [#208](https://github.com/phntmxyz/sidekick/pull/208)

### Other Changes
- New `List<DartPackage> findAllPackages(Directory)` function to find packages in directories such as `SidekickContext.projectRoot` or `SidekickContext.repository` [#178](https://github.com/phntmxyz/sidekick/pull/178)
- Require latest dartx version `1.1.0` [#208](https://github.com/phntmxyz/sidekick/pull/208)
- Update template to use Dart 2.18.6 [#195](https://github.com/phntmxyz/sidekick/pull/195)
- Show the exact version of the plugin during install [#203](https://github.com/phntmxyz/sidekick/pull/203)
- Print `pub get` errors when installing plugin [#203](https://github.com/phntmxyz/sidekick/pull/203)
- Fix misleading update message [#210](https://github.com/phntmxyz/sidekick/pull/210)

## [0.15.1](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v0.15.0..sidekick_core-v0.15.1) (2023-1-18)

- **bugfix**: sidekick update - Ignore insignificant `pub get` errors [#190](https://github.com/phntmxyz/sidekick/pull/190)

## [0.15.0](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v0.14.0..sidekick_core-v0.15.0) (2023-1-18)

### Changes to your sidekick CLI

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

## [0.14.0](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v0.13.1..sidekick_core-v0.14.0) (2023-1-6)

### Template Changes

- CLI template now does **not** generate a `<cli>_project.dart` file. You can continue to use yours but we found most people didn't need it. ([#156](https://github.com/phntmxyz/sidekick/pull/156))
- UsageException is now correctly printed ([#157](https://github.com/phntmxyz/sidekick/pull/157)) (with `<cli> sidekick update` migration)
- Calling the CLI with zero arguments now also checks for sidekick updates ([#157](https://github.com/phntmxyz/sidekick/pull/157)) (with `<cli> sidekick update` migration)
- Fix unnecessary CLI recompilation in `run.sh` ([#152](https://github.com/phntmxyz/sidekick/pull/152))

### API Changes

- New `DartPackage.lockfile` getter ([#159](https://github.com/phntmxyz/sidekick/pull/159))
- New `DartPackage.fromArgResults` constructor for Commands that take a package as only argument. Parses `rest` and `cwd`. ([#160](https://github.com/phntmxyz/sidekick/pull/160))
- `SidekickTemplateProperties` now has optional properties. Caller has to decide what to inject for each template. ([#161](https://github.com/phntmxyz/sidekick/pull/161))

## 0.13.1
- Fix `sidekick plugins install` for git and local sources #144

## 0.13.0
- New `sidekick update` command for updating your sidekick CLI (#111)
- Add `excludeGlob` parameter to `DepsCommand` (#125)
- Add `--version` flag to `sidekick` command
- Support `FLUTTER_ROOT` environment variable for local Flutter SDK (#123)
- Update templates (#132, #126)
- Installing sidekick plugins from git is now possible (#126)
- Experimental: Automatic sidekick update check when setting `SIDEKICK_ENABLE_UPDATE_CHECK` environment variable to `true`

## 0.12.0
- New: `version` getter mirroring the `sidekick_core` version in `pubspec.yaml`
- Analyzer now ignores the `build` folder. Previously, the embedded dart sdk was accidentally analyzed #107  
- Reduce stdout noise when installing a plugin from pub (`sidekick plugin install`) #109
- Reduce stdout when compiling the cli (not showing `dart pub get` stdout) #109
- Allow cli names to include underscores (sidekick init) #112
- `DepsCommand` now accounts for the `exclude` parameter, not loading dependencies for those packages #118

## 0.11.1
- New: `<FileSystemEntity>.makeExecutable()` extension method
- Update repository URL in pubspec.yaml
- Move cli template into `sidekick_core`

## 0.11.0
- New: `addFlutterSdkInitilizer` method to allow plugins downloading the Flutter SDK before `flutter` is called #99
- Widen `dcli` version range

## 0.10.1

- Fix `install-global` command which crashed in some cases (#94)

## 0.10.0

- Template shared-command and shared-code now use the `library` keyword #87
- `findAllPackages` works now outside of the `SidekickCommandRunner`
- New `OutOfCommandRunnerScopeException` when accessing `cliName` and friends outside of a `Command` #88
- Allow execution of `PluginCommand` from our `sidekick` cli using the system dart sdk #91
- New `SidekickCommand` that bundles now `plugins`, `recompile` and `install-global` #89

## 0.9.0

- Fix: Setting `flutterSdkPath` and `dartSdkPath` in `initializeSidekick` now works with relative paths from anywhere as well.  
  Relative paths are resolved relative to the project root.
- New: The `plugins create` command now also generates a `README.md`, `.gitignore`, and `analysis_options.yaml`
- New: `DepsCommand` (previously was in `sidekick`)
- New: `RecompileCommand` (previously was in `sidekick`)
- New: Functions returning system Dart/Flutter SDKs (`systemDartSdk`, `systemDartSdkPath`, `systemFlutterSdk`, `systemFlutterSdkPath`)

## 0.8.0

- `DartCommand` and `FlutterCommand` now require the SDKs to be set in `initializeSidekick(flutterSdkPath: ..., dartSdkPath: ...)`.)`. This is a non-breaking change, falling back to `flutter_wrapper`.
- Breaking: Plugins now use a zero argument main function. All information during install is injected via env, accessible with `PluginContext` #72
- New: `DartPackage` doesn't require a `lib` directory anymore #63
- Add: `SidekickPackage.cliMainFile` location where plugins are registered

## 0.7.1

- New: `plugins create` now generates plugins from templates
- Fix: `plugins install` now uses a temp working directory instead of manipulating the pub cache during install
- New: `isValidPubPackageName(String name)` returns `true` when the name is a valid pub package name according to <https://dart.dev/tools/pub/pubspec#name>

## 0.7.0

- New: `PluginsCommand` to automatically install plugins to easily extend sidekick CLIs
- New: `SidekickDartRuntime sidekickDartRuntime` that points to the dart sdk bundled with the CLI
- New: `Repository.sidekickPackage` which returns `Repository.cliPackageDir` as  `SidekickPackage` object.

## 0.6.0

- **Breaking** `initializeSidekick()` now returns a `SidekickCommandRunner` instance (was `void`). You have to use this runner to access the global sidekick variables `cliName`, `mainProject`,`repository`
- Regenerate your cli with `sidekick: 0.6.0` to migrate

## 0.5.2
- constrain `dcli`, new versions are not compatible with Dart 2.15 and below

## 0.5.1
- Print script + stderr when execution of an inline script (`writeAndRunShellScript(script)`) fails

## 0.5.0

**Breaking** This update requires the sidekick project to be initialized again with `sidekick: 0.4.0`

- New `InstallGlobalCommand` (links binaries in `$HOME/.sidekick/bin`)
- Simplified repository detection (breaking)
- `error` now support errorCode

## 0.4.1
- Require Dart 2.14

## 0.4.0
- `flutterw()` is now windows compatible
- `dart()` is now windows compatible
- DartPackage detection prints a warning for packages without a `lib/` dir

## 0.3.3

- Update `dcli` to `1.15.0` due to [breaking change](https://github.com/noojee/dcli/commit/d8a68546127fa5c7b32f1f97eb3020e79605c873)

## 0.3.2

- Update `dcli`
- Widen `dartx` version range

## 0.3.1

- `AnalyzeCommand` now fails with correct exit code

## 0.3.0

- Include `ForwardCommand` and add `flutterw`, `dart` and `analyze` subcommands

## 0.2.0

- Add `initializeSidekick()`
- Add `repository`, `cliName` and `mainProject`
- Add util files
