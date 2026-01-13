# Changelog

## [3.1.0](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v3.0.1..sidekick_core-v3.1.0) (2026-1-13)

- Upgrade sidekick_core to dcli 8 [#280](https://github.com/phntmxyz/sidekick/pull/280) <https://github.com/phntmxyz/sidekick/commit/d24ed64effcc958400e4bc292c7df50fed9af8a7>
- Add TestCommand (`<cli> test`) [#279](https://github.com/phntmxyz/sidekick/pull/279) <https://github.com/phntmxyz/sidekick/commit/45d35160e82dcdd1d286f9cc3c2f38f37adff558>
- Fix `format` command, using the wrong workingDir <https://github.com/phntmxyz/sidekick/commit/f9f64ca025d77c33b16fe5fdfbdc4b39083ea12b>
- Update plugin templates <https://github.com/phntmxyz/sidekick/commit/a0256b6c213d6179f25570d5694208bf2023853f>

## [3.0.1](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v3.0.0..sidekick_core-v3.0.1) (2025-6-30)

Full diff: <https://github.com/phntmxyz/sidekick/compare/sidekick_core-v3.0.0...main>

- Add migration for `addFlutterSdkInitializer` [#272](https://github.com/phntmxyz/sidekick/pull/272)
- Update cli_completion to `0.5.0` <https://github.com/phntmxyz/sidekick/commit/f4dc024a8af7701b5d1c7df92daf0efed3f6cab1>
- [format] Hide excludeGlob excluded packages entirely from output [#273](https://github.com/phntmxyz/sidekick/pull/273)
- Await plugin installer calls <https://github.com/phntmxyz/sidekick/commit/33d5b736b8351f8188b4a64f8db7eb019c12a67d>

## [3.0.0](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v3.0.0-preview.6..sidekick_core-v3.0.0) (2025-6-25)

Full diff: https://github.com/phntmxyz/sidekick/compare/sidekick_core-v3.0.0-preview.6...main

Big release, you most likely have to update your code:

- Breaking: `dart()` and `flutter()` are now async. Don't forget to add `await` everywhere! [#256](https://github.com/phntmxyz/sidekick/pull/256)
- Breaking: Replaced `addFlutterSdkInitializer` with `addSdkInitializer`. It now gets way more information via `SdkInitializerContext`. This method may now be called way more often, always before every `flutter`, `dart` execution. [#256](https://github.com/phntmxyz/sidekick/pull/256)
- Breaking: Removed `PubSpec` class. Please manually add [pubspec_manager](https://pub.dev/packages/pubspec_manager) and replace [`pubspec2`](https://pub.dev/packages/pubspec2). Use `import 'package:pubspec_manager/pubspec_manager.dart' hide Version;` and access the pubspec version via `PubSpec.loadFromPath(path).version.semVersion`.
- Update to dcli 7.0.2
- Update to Dart 3.5

Minor changes since `3.0.0-preview.6`

- Hide incompatible Dart versions (e.g. 3.4.0) [#270](https://github.com/phntmxyz/sidekick/pull/270)
- Add dart-internal command for direct access to embedded Dart SDK [#269](https://github.com/phntmxyz/sidekick/pull/269)
- Convert all bash to sh files for wider compatability [#268](https://github.com/phntmxyz/sidekick/pull/268)
- Make all dart functions futures [#267](https://github.com/phntmxyz/sidekick/pull/267)
- Fix updating from one to another preview (by setting the version manually) [#266](https://github.com/phntmxyz/sidekick/pull/266)

## [3.0.0-preview.6](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v3.0.0-preview.5..sidekick_core-v3.0.0-preview.6) (2025-6-7)

Full diff: <https://github.com/phntmxyz/sidekick/compare/sidekick_core-v3.0.0-preview.5...main>

- Do not offer older versions then the specific requested one also for preview [#262](https://github.com/phntmxyz/sidekick/pull/262)
- Update pubspec_manager to 1.0.2 [#264](https://github.com/phntmxyz/sidekick/pull/264)
- Add support for analysis_options formatter.page_width and remove --fix [#261](https://github.com/phntmxyz/sidekick/pull/261)
- Fix migrations [#263](https://github.com/phntmxyz/sidekick/pull/263)

## [3.0.0-preview.5](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v3.0.0-preview.4..sidekick_core-v3.0.0-preview.5) (2025-4-14)

Full diff: https://github.com/phntmxyz/sidekick/compare/sidekick_core-v3.0.0-preview.4...main

- Remove set Dart SDK Version and change migration target to preview.5 https://github.com/phntmxyz/sidekick/commit/15691e281ee6d6b0a226df50e7bcf18c36ceeda0

## [3.0.0-preview.4](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v3.0.0-preview.3..sidekick_core-v3.0.0-preview.4) (2025-4-14)

Full diff: https://github.com/phntmxyz/sidekick/compare/sidekick_core-v3.0.0-preview.3...main

- Change migration target version to 3.0.0-preview.4 https://github.com/phntmxyz/sidekick/commit/06e7d83ddfc8bad578c1d1cd9c62cace9284e3e5

## [3.0.0-preview.3](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v3.0.0-preview.2..sidekick_core-v3.0.0-preview.3) (2025-4-14)

Full diff: https://github.com/phntmxyz/sidekick/compare/sidekick_core-v3.0.0-preview.2...main

- Switch from pubspec2 to pubspec_manager https://github.com/phntmxyz/sidekick/commit/501b84c29637c8ebab2b3ff4119e5a812e1eabde
- Update to dart 3.5 https://github.com/phntmxyz/sidekick/commit/e229b29343f873ffbe28d5bae22afd998943e2d3
- Update to dcli 7.0.2 https://github.com/phntmxyz/sidekick/commit/975fcd4ee14e6e57b94efe8d1923fc424de3e56a

## [3.0.0-preview.2](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v3.0.0-preview.1..sidekick_core-v3.0.0-preview.2) (2024-7-22)

- Fix SdkInitializerContext.package when calling dart format [#258](https://github.com/phntmxyz/sidekick/pull/258) https://github.com/phntmxyz/sidekick/commit/50e907cb656099bde1e80ad2da0d20525836e5c6
- Update sidekick_plugin_installer https://github.com/phntmxyz/sidekick/commit/ea519a97d3f280251f2be76c4b2a8f5d6d6ed6c9

## [3.0.0-preview.1](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v2.1.2..sidekick_core-v3.0.0-preview.1) (2024-7-16)

- Breaking: `dart()` and `flutter()` are now async. Don't forget to add `await` everywhere! [#256](https://github.com/phntmxyz/sidekick/pull/256)
- Breaking: Migrate to dcli:^4.0.4 [#255](https://github.com/phntmxyz/sidekick/pull/255) <https://github.com/phntmxyz/sidekick/commit/8969b3127281844e5ff5ed5e63f8ba77da7d808e>
- Raise minimum Dart version to 3.3.0
- Breaking: Replaced `addFlutterSdkInitializer` with `addSdkInitializer`. It now gets way more information via `SdkInitializerContext`. This method may now be called way more often, always before every `flutter`, `dart` execution. [#256](https://github.com/phntmxyz/sidekick/pull/256)
- Pub workspaces are not detected as packages anymore <https://github.com/phntmxyz/sidekick/commit/c6e8f97cf5faccd6f2ff59dcd2ea312dddfdfc09>

## [2.1.3](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v2.1.2..sidekick_core-v2.1.3) (2024-7-16)

- Allow updating to sidekick_core:3.0.0-preview with Dart 3.3.0+ <https://github.com/phntmxyz/sidekick/commit/a330aa7b938e25ac10b5e8862cda7c6912e4a15c>
- Do not detect workspaces as dart packages <https://github.com/phntmxyz/sidekick/commit/e2346ad1558d745297b394220e8d56a5fafcabbf>

## [2.1.2](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v2.1.1..sidekick_core-v2.1.2) (2024-4-5)

- Max Dart SDK 3.2.X [#254](https://github.com/phntmxyz/sidekick/pull/254)
- Force adding pubspec.lock regardless of other repo rules [#253](https://github.com/phntmxyz/sidekick/pull/253)

## [2.1.1](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v2.1.0..sidekick_core-v2.1.1) (2024-4-5)

- Hotfix: Constrain dart_console2 dependencies [#252](https://github.com/phntmxyz/sidekick/pull/252)

## [2.1.0](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v2.0.6..sidekick_core-v2.1.0) (2023-9-26)

- **NEW:** Added tab completion - automatically available by upgrading sidekick_core to this version! [#245](https://github.com/phntmxyz/sidekick/pull/245) https://github.com/phntmxyz/sidekick/commit/dd7b18f07dd792ed9fd3c3a37bc73f254aa807c9
- Updated README https://github.com/phntmxyz/sidekick/commit/48f58c0b883dab552181b9d25165bdfc05006136

## [2.0.6](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v2.0.5..sidekick_core-v2.0.6) (2023-8-22)

- widen `http` constraint #243

## [2.0.5](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v2.0.4..sidekick_core-v2.0.5) (2023-7-6)

- Fixed a bug ([#240](https://github.com/phntmxyz/sidekick/issues/240)) in the plugin templates along with some other minor improvements [#242](https://github.com/phntmxyz/sidekick/pull/242)

## [2.0.4](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v2.0.3..sidekick_core-v2.0.4) (2023-7-2)

- Constrain `pubspec2` dependency in to circumvent broken dependency chain [#236](https://github.com/phntmxyz/sidekick/pull/236) https://github.com/phntmxyz/sidekick/commit/9b367347133614fb9c0f2d66f7d3cc5c1a9dcf64

## [2.0.3](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v2.0.2..sidekick_core-v2.0.3) (2023-6-30)

- Show warning when using deps command outside of the project [#235](https://github.com/phntmxyz/sidekick/pull/235) https://github.com/phntmxyz/sidekick/commit/e6b1a7e634536b4bf07f5f688483394cc510d99e

## [2.0.2](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v2.0.1..sidekick_core-v2.0.2) (2023-6-5)

- Fix analysis issues in templates

## [2.0.1](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v2.0.0..sidekick_core-v2.0.1) (2023-6-5)

- Update templates

## [2.0.0](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v2.0.0-preview.2..sidekick_core-v2.0.0) (2023-6-5)

- Constrain upper bound of dcli to be 100% Dart 2.19 compatible for easy migration

## [2.0.0-preview.2](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v2.0.0-preview.1..sidekick_core-v2.0.0-preview.2) (2023-5-30)

- Propose all dart versions when installing specific sidekick_core version https://github.com/phntmxyz/sidekick/commit/775d15661b715bd617f10159b5e1d4487b4f2396
- Fix package name when installing sidekick_core preview versions https://github.com/phntmxyz/sidekick/commit/ebdf5b968b67d51b036732baa05ab26768990e1e
- Handle pre-releases in update check https://github.com/phntmxyz/sidekick/commit/3560070892f485a84473c84d97acca2ca67f073c

## [2.0.0-preview.1](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v1.3.0..sidekick_core-v2.0.0-preview.1) (2023-5-30)

- [Dart 3] Update sidekick_core & CI [#228](https://github.com/phntmxyz/sidekick/pull/228)

## [1.3.0](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v1.2.0..sidekick_core-v1.3.0) (2023-5-24)

This release is necessary for future support for Dart 3.0. Please do update to this version, before upgrading to `sidekick_core: ^2.0.0` with Dart 3.0 support.

- Fix `<cli> sidekick update` and only suggest compatible Dart SDK / sidekick_core combinations [#229](https://github.com/phntmxyz/sidekick/pull/229) https://github.com/phntmxyz/sidekick/commit/bd1121cc99f72173d474dfebd95ffb877c402121
- Move to branch `main-1.X` for `1.X.X` releases [#230](https://github.com/phntmxyz/sidekick/pull/230) https://github.com/phntmxyz/sidekick/commit/c03f9fcb1f116e297e1f1849dc63f4e8b9c8ad86

## [1.2.0](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v1.1.0..sidekick_core-v1.2.0) (2023-5-11)

- Add topics to `pubspec.yaml`
- Add `CreateCommand` (register and generate a command) [#226](https://github.com/phntmxyz/sidekick/pull/226) https://github.com/phntmxyz/sidekick/commit/74771b8508e24804826bad4e40a7a80531ded8e3
- Add migration to install `FormatCommand` on update [#225](https://github.com/phntmxyz/sidekick/pull/225) https://github.com/phntmxyz/sidekick/commit/a8bd02510f1a9acbaca9e868a2e43cb0ffdf5cb1
- Fix `FormatCommand` `--verify` exception message, print unformatted files [#224](https://github.com/phntmxyz/sidekick/pull/224) https://github.com/phntmxyz/sidekick/commit/b30030c11731f8b39e31884fb57a8c1d751384c0
- `FormatCommand.formatGenerated` allows ignoring generated files (.g.dart) [#223](https://github.com/phntmxyz/sidekick/pull/223) https://github.com/phntmxyz/sidekick/commit/46b4a64cafafa83cfa62623fb1c986691e18b202

## [1.1.0](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v1.0.2..sidekick_core-v1.1.0) (2023-2-3)

- New: `FormatCommand` (`<cli> format`) to format all your project dart code [#192](https://github.com/phntmxyz/sidekick/pull/192)
- Fix: plugin install with Dart 2.19 (default pub hosted url changed) [#221](https://github.com/phntmxyz/sidekick/pull/221)
- install script does major dependency update [#220](https://github.com/phntmxyz/sidekick/pull/220)

## [1.0.2](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v1.0.1..sidekick_core-v1.0.2) (2023-1-25)

- Update templates to `sidekick_core: ^1.0.0` and `sidekick_plugin_installer: ^0.3.0`  [#214](https://github.com/phntmxyz/sidekick/pull/214)
- Don't show a warning when `flutterSdkPath` or `dartSdkPath` is an absolute path. [#214](https://github.com/phntmxyz/sidekick/pull/214)

## [1.0.1](https://github.com/phntmxyz/sidekick/compare/sidekick_core-v1.0.0..sidekick_core-v1.0.1) (2023-1-25)

- Support for sidekick_plugin_installer:3.0.0 [#213](https://github.com/phntmxyz/sidekick/pull/213)

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
