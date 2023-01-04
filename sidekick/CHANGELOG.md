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
