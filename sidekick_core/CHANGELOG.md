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
