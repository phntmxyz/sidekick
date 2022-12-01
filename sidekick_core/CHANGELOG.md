# Changelog

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
