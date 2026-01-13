# Changelog

## [2.1.0](https://github.com/phntmxyz/sidekick/compare/sidekick_plugin_installer-v2.0.0..sidekick_plugin_installer-v2.1.0) (2026-1-13)

- Upgrade sidekick_core to 3.1.0 <https://github.com/phntmxyz/sidekick/commit/b9b2124b0c0927a9ea9a146244447e5a49d410b4>
- Upgrade dcli to 8.2.0 [#280](https://github.com/phntmxyz/sidekick/pull/280) <https://github.com/phntmxyz/sidekick/commit/d24ed64effcc958400e4bc292c7df50fed9af8a7>
- Remove unnecessary library name <https://github.com/phntmxyz/sidekick/commit/43bbc01ced7c4c96c95a0c713248235b095a0111>
- Await plugin installer calls <https://github.com/phntmxyz/sidekick/commit/33d5b736b8351f8188b4a64f8db7eb019c12a67d>

## [2.0.0](https://github.com/phntmxyz/sidekick/compare/sidekick_plugin_installer-v1.3.0..sidekick_plugin_installer-v2.0.0) (2025-6-25)

Full diff: <https://github.com/phntmxyz/sidekick/compare/sidekick_plugin_installer-v1.3.0...main>

- Remove deprecated `pubAddDependency()` (use addDependency instead)
- Remove deprecated `pubAddLocalDependency()` (use addDependency instead)
- Make `addDependency()` and `addSelfAsDependency()` async
- Make `pubGet()` async
- Update to sidekick_core 3.0.0

## [1.3.0](https://github.com/phntmxyz/sidekick/compare/sidekick_plugin_installer-v1.2.1..sidekick_plugin_installer-v1.3.0) (2025-4-14)

Full diff: https://github.com/phntmxyz/sidekick/compare/sidekick_plugin_installer-v1.2.1...main

- Set sidekick core version to 3.0.0-preview.5
- Requires Dart 3.5
- Update to dcli 7.0.2

## [1.2.1](https://github.com/phntmxyz/sidekick/compare/sidekick_plugin_installer-v1.2.0..sidekick_plugin_installer-v1.2.1) (2024-7-16)

- allow analyzer 6.x.y <https://github.com/phntmxyz/sidekick/commit/7c5a0d66f1acc60cb97b2156490661e40d156105>

## [1.2.0](https://github.com/phntmxyz/sidekick/compare/sidekick_plugin_installer-v1.1.0..sidekick_plugin_installer-v1.2.0) (2024-7-16)

- Update sidekick_core: ^3.0.0-preview.1
- Migrate to dcli:4.x [#255](https://github.com/phntmxyz/sidekick/pull/255)

## [1.1.0](https://github.com/phntmxyz/sidekick/compare/sidekick_plugin_installer-v1.0.0..sidekick_plugin_installer-v1.1.0) (2023-6-5)

- Update to sidekick_core: 2.0.0 (stable)

## [1.0.0](https://github.com/phntmxyz/sidekick/compare/sidekick_plugin_installer-v0.3.1..sidekick_plugin_installer-v1.0.0) (2023-5-30)

- Make sidekick_plugin_installer Dart 3 compatible

## [0.3.1](https://github.com/phntmxyz/sidekick/compare/sidekick_plugin_installer-v0.3.0..sidekick_plugin_installer-v0.3.1) (2023-5-11)

- Add topics to `pubspec.yaml`
- Prevent double imports when registering a plugin [#179](https://github.com/phntmxyz/sidekick/pull/179) https://github.com/phntmxyz/sidekick/commit/ce8f44d0ea8f6d74a2f3ca75c86684780cd92543
- Update `sidekick_core` dependency to `1.0.0`

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
