# Changelog

## [0.3.0](https://github.com/phntmxyz/sidekick/compare/sidekick_plugin_installer-v0.2.1..sidekick_plugin_installer-v0.3.0) (2023-1-25)

- Update sidekick_core to `1.0.0` https://github.com/phntmxyz/sidekick/commit/e22cc2d61fc8b9eeca33097b240fdadeb8f8e006
- Simplify install script path pattern check [#139](https://github.com/phntmxyz/sidekick/pull/139)

## 0.2.1

- Make `PluginContext.name` nullable, because it is not available in protocol v1. (#137)

## 0.2.0

- Deprecate `pubAddDependency` in favor of `addSelfAsDependency`and `addDependency` (#136)
- Deprecate `pubAddLocalDependency` in favor of `addSelfAsDependency`and `addDependency` (#136)
- Add example folder
- Update repository link
- Add `addSelfAsDependency` (#136)
- Add `addDependency` (#136)
- Add `PluginContext.name` (#136)
- Add `PluginContext.versionConstraint` (#136)
- Add `PluginContext.localPath` (#136)
- Add `PluginContext.hostedUrl` (#136)
- Add `PluginContext.gitUrl` (#136)
- Add `PluginContext.gitPath` (#136)
- Add `PluginContext.installerPlugin` (#132)
- Fix: `registerPlugin` does not add duplicated command anymore if it has already been added (#131)

## 0.1.3

- New: `PluginContext` (#72)

## 0.1.2

- New: `pubAddLocalDependency`

## 0.1.1
- Widen analyzer range to support Dart 2.14

## 0.1.0

- New: `addImport`
- New: `pubAddDependency`
- New: `pubGet`
- New: `registerPlugin`
