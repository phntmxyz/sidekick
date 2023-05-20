import 'package:meta/meta.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/pub/dart_archive.dart';
import 'package:sidekick_core/src/version_checker.dart';

/// Updates the sidekick cli
class UpdateCommand extends Command {
  @override
  final String description = 'Updates the sidekick cli';

  @override
  final String name = 'update';

  @override
  String get invocation => super.invocation.replaceFirst(
        '[arguments]',
        "[{<version>, 'latest'}]",
      );

  DartArchive _dartArchive = DartArchive();

  @override
  Future<void> run() async {
    final args = argResults!;

    final Version? version = args.versionFromRest(
      formatError: (rest) {
        usageException("'$rest' is not a valid semver version.");
      },
    );

    // Start from current sdk version, we don't want to downgrade
    final currentMinVersion = VersionChecker.getMinimumVersionConstraint(
          SidekickContext.sidekickPackage,
          ['environment', 'sdk'],
        ) ??
        Version(2, 19, 0);

    final currentMinVersionIgnoringPatch = currentMinVersion.ignorePatch;

    final futureDartSdkVersions = await _dartArchive
        .getLatestDartVersions()
        .where((version) => version >= currentMinVersion)
        .toList();

    final futureDartSdkVersionWithLatestPatch = futureDartSdkVersions
        .groupBy((v) => Version(v.major, v.minor, 0))
        .mapEntries((versionGroup) => versionGroup.value.maxBy((v) => v.patch)!)
        .toList();

    final mappedSidekickCoreVersions = await Future.wait<Version?>(
      futureDartSdkVersionWithLatestPatch.map((dartVersion) {
        return VersionChecker.getLatestDependencyVersion(
          'sidekick_core',
          dartSdkVersion: dartVersion,
        );
      }),
    );

    final List<MapEntry<Version, Version>> sdksWithValidCoreMapping =
        futureDartSdkVersionWithLatestPatch
            .zip(mappedSidekickCoreVersions,
                (Version sdkVersion, Version? coreVersion) {
              return MapEntry(sdkVersion, coreVersion);
            })
            .where((entry) => entry.value != null)
            .map((entry) => MapEntry(entry.key, entry.value!))
            .toList();

    final List<Version> compatibleSdks =
        sdksWithValidCoreMapping.map((it) => it.key).toList();

    final latestDartVersion = compatibleSdks.last;

    print(white('Which Dart SDK version do you want to use?'));
    final dartVersionToInstall = menu(
      prompt: 'Dart Version',
      options: [...compatibleSdks],
      defaultOption: latestDartVersion,
      format: (Object? option) {
        // ignore: cast_nullable_to_non_nullable
        final version = Version.parse(option as String);
        if (version.ignorePatch == currentMinVersionIgnoringPatch) {
          return '$version (current)';
        }
        if (version.ignorePatch == latestDartVersion) {
          return '$version (latest)';
        }
        return version.toString();
      },
    );

    final Version mappedSidekickCoreVersion = sdksWithValidCoreMapping
        .firstWhere((entry) => entry.key == dartVersionToInstall)
        .value;
    final Version coreVersionToInstall = version ?? mappedSidekickCoreVersion;

    // to remember which sidekick_core version the sidekick CLI was generated
    // with, that sidekick_core version is written into the CLI's pubspec.yaml
    // at the path ['sidekick', 'cli_version']
    final currentSidekickCliVersion =
        VersionChecker.getMinimumVersionConstraint(
              SidekickContext.sidekickPackage,
              ['sidekick', 'cli_version'],
            ) ??
            Version.none;

    if (coreVersionToInstall <= currentSidekickCliVersion) {
      print('No need to update because you are already using the '
          'latest sidekick cli version.');
      return;
    }

    // kick of the update process
    updateSidekickCli(
      from: currentSidekickCliVersion,
      to: coreVersionToInstall,
      dartSdkVersion: dartVersionToInstall,
    );
  }

  /// Updates the sidekick cli to the new [to] version by loading `sidekick_core`
  /// with version `to` from pub and running the bundled update script from that
  /// package version.
  ///
  /// The update script is located at `lib/src/update_sidekick_cli.dart`
  void updateSidekickCli({
    required Version from,
    required Version to,
    required Version dartSdkVersion,
  }) {
    // run the update script (`update_sidekick_cli.dart`) from the updated
    // sidekick_core with version [to]
    startUpdateScriptProcess(
      coreFrom: from,
      coreTo: to,
      dartSdkVersion: dartSdkVersion,
    );

    _dartCommand(
      ['pub', 'get'],
      workingDirectory: SidekickContext.sidekickPackage.root,
      progress: Progress.devNull(),
      // This pub get is a nice to have, and it doesn't matter if it fails or
      // not. It may fail when the Dart SDK version has been updated, because
      // `_dartCommand` still uses the "old" Dart SDK.
      // The new SDK will be downloaded with the next execution.

      // For all other errors: They become visible the next time the cli is executed
      nothrow: true,
    );
  }

  /// Runs the update script `update_sidekick_cli.dart` in a new process using
  /// the `sidekick_core` package at the exact version that is specified in
  /// pubspec.lock
  ///
  /// The current process - running `sidekick update` - can't access code of other
  /// version of sidekick_core. Dependencies can't be changed at runtime.
  /// This workaround allows accessing any version of sidekick_core.
  ///
  /// Make sure to update the sidekick_core dependency before starting this
  /// process.
  void startUpdateScriptProcess({
    required Version coreFrom,
    required Version coreTo,
    required Version dartSdkVersion,
  }) {
    final updateName =
        'update_${coreTo.canonicalizedVersion}'.replaceAll('.', '_');
    final updateScriptDir =
        SidekickContext.sidekickPackage.buildDir.directory(updateName);
    updateScriptDir.file('pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: $updateName
environment:
  sdk: '>=${dartSdkVersion.canonicalizedVersion} <${dartSdkVersion.nextBreaking.canonicalizedVersion}'
dependencies:
  sidekick_core: ${coreTo.canonicalizedVersion}

''');

    final updateScript = updateScriptDir.file('bin/update.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'package:sidekick_core/src/update_sidekick_cli.dart' as update;
Future<void> main(List<String> args) async {
  await update.main(args);
}
  ''');

    // Download the new Dart SDK
    // update the Dart SDK version in pubspec.yaml, so that the download_dart.sh
    // script can pick up the correct version
    print('Downloading Dart SDK $dartSdkVersion');
    VersionChecker.updateVersionConstraint(
      package: SidekickContext.sidekickPackage,
      pubspecKeys: ['environment', 'sdk'],
      newMinimumVersion: dartSdkVersion,
      preferCaret: false,
    );
    sidekickDartRuntime.download();

    _dartCommand(
      ['pub', 'get'],
      workingDirectory: updateScriptDir,
      progress: Progress.printStdErr(),
    );

    try {
      // Do not change the arguments in a breaking way. The `update_sidekick_cli.dart`
      // script will be called from another sidekick_core version. Changes will break
      // the update process.
      // Only add parameters, never remove any.
      _dartCommand(
        [
          updateScript.path,
          SidekickContext.cliName,
          coreFrom.canonicalizedVersion,
          coreTo.canonicalizedVersion,
        ],
        progress: Progress.print(),
      );
    } finally {
      updateScript.deleteSync();
    }
  }
}

extension on ArgResults {
  Version? versionFromRest({void Function(String rest)? formatError}) {
    if (rest.isEmpty) {
      return null;
    }
    if (rest.first == 'latest') {
      return null;
    }
    try {
      return Version.parse(rest.first);
    } on FormatException catch (_) {
      formatError?.call(rest.join(' '));
      return null;
    }
  }
}

extension on Version {
  Version get ignorePatch => Version(major, minor, 0);
}

/// Executes a dart command, usually from the embedded Dart SDK
/// [SidekickDartRuntime.dart] or [dart] in case the sidekick CLI was created
/// before `sidekick_core: 0.10.0`.
///
/// This workaround is only required within this command. If any other command
/// fails because it is missing the embedded Dart SDK, the user should update
/// their cli.
void Function(
  List<String> args, {
  Progress? progress,
  Directory? workingDirectory,
  bool nothrow,
}) get _dartCommand {
  return sidekickDartRuntime.isDownloaded() ? sidekickDartRuntime.dart : dart;
}

extension UpdateCommandTestInjector on UpdateCommand {
  @visibleForTesting
  set dartArchive(DartArchive archive) => _dartArchive = archive;
}
