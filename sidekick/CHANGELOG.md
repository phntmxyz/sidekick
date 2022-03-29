# Changelog

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
