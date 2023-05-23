import 'package:meta/meta.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/pub/dart_archive.dart';
import 'package:sidekick_core/src/template/update_executor.template.dart';
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

    final List<Version> availableSidekickCoreVersion =
        sdksWithValidCoreMapping.map((it) => it.value).toList();
    final latestSidekickCoreVersion = availableSidekickCoreVersion.lastOrNull;

    // to remember which sidekick_core version the sidekick CLI was generated
    // with, that sidekick_core version is written into the CLI's pubspec.yaml
    // at the path ['sidekick', 'cli_version']
    final currentSidekickCliVersion =
        VersionChecker.getMinimumVersionConstraint(
              SidekickContext.sidekickPackage,
              ['sidekick', 'cli_version'],
            ) ??
            Version.none;

    final Version coreVersionToInstall;
    if (version != null) {
      if (!version.isPreRelease &&
          !availableSidekickCoreVersion.contains(version)) {
        print(
          "'$version' is not a valid/compatible sidekick_core version, "
          "visit https://pub.dev/packages/sidekick_core/versions for more info.",
        );
        return;
      }
      coreVersionToInstall = version;
    } else {
      if (availableSidekickCoreVersion.isEmpty) {
        print('No compatible sidekick_core version found, '
            'visit https://pub.dev/packages/sidekick_core/versions for more info.');
        return;
      }
      if (availableSidekickCoreVersion.length == 1) {
        coreVersionToInstall = availableSidekickCoreVersion.first;
      } else {
        print(white('Which sidekick_core version do you want to install?'));
        coreVersionToInstall = menu(
          prompt: 'sidekick_core Version',
          options: [...availableSidekickCoreVersion],
          defaultOption: latestSidekickCoreVersion,
          format: (Object? option) {
            // ignore: cast_nullable_to_non_nullable
            final version = option as Version;
            if (version == currentSidekickCliVersion) {
              return '$version (current)';
            }
            if (version == latestSidekickCoreVersion) {
              return '$version (latest)';
            }
            return version.toString();
          },
        );
      }
    }

    final dartVersionToInstall = sdksWithValidCoreMapping
        .firstWhere((entry) => entry.value == coreVersionToInstall)
        .key;

    if (coreVersionToInstall <= currentSidekickCliVersion) {
      print('No need to update because you are already using the '
          'latest sidekick_core:$currentSidekickCliVersion version for Dart $dartVersionToInstall.');
      return;
    }
    print(
      'Updating sidekick to version $coreVersionToInstall (Dart $dartVersionToInstall)',
    );

    // Download the new Dart SDK version
    // Update the Dart SDK version in pubspec.yaml, so that the download_dart.sh
    // script can pick up the correct version
    if (currentMinVersion != dartVersionToInstall) {
      print('Downloading Dart SDK $dartVersionToInstall');
      VersionChecker.updateVersionConstraint(
        package: SidekickContext.sidekickPackage,
        pubspecKeys: ['environment', 'sdk'],
        newMinimumVersion: dartVersionToInstall,
        preferCaret: false,
      );
      sidekickDartRuntime.download();
    }

    final updateName = 'update_${coreVersionToInstall.canonicalizedVersion}'
        .replaceAll('.', '_');
    final updateScriptDir =
        SidekickContext.sidekickPackage.buildDir.directory(updateName);

    final executor = UpdateExecutor(
      location: updateScriptDir,
      oldSidekickCoreVersion: currentSidekickCliVersion,
      newSidekickCoreVersion: coreVersionToInstall,
      dartSdkVersion: dartVersionToInstall,
    );

    try {
      // Write update package with just the updated sidekick_core dependency and the chosen Dart SDK version
      // This prevents any version conflicts and the entire sidekick update will
      // be executed from the new sidekick_core version and can be updated.
      executor.generateUpdatePackage();

      // Execute the update script of the new sidekick_core version with the new Dart SDK version
      executor.pubGet();
      executor.executeSidekickUpdate();
    } finally {
      // cleanup
      updateScriptDir.deleteSync(recursive: true);
    }

    // Run pub get on cli package to download the new sidekick_core version
    // (sidekick_core was updated by the update script)
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

/// Creates a temporary update package that executes `update_sidekick_cli.dart`
/// from sidekick_core at version [newSidekickCoreVersion] with Dart SDK version
/// [dartSdkVersion] in a separate process.
class UpdateExecutor {
  UpdateExecutor({
    required this.location,
    required this.dartSdkVersion,
    required this.oldSidekickCoreVersion,
    required this.newSidekickCoreVersion,
  });

  final Directory location;
  final Version dartSdkVersion;
  final Version oldSidekickCoreVersion;
  final Version newSidekickCoreVersion;

  /// First generate the update package
  void generateUpdatePackage() {
    final template = UpdateExecutorTemplate(
      location: location,
      dartSdkVersion: dartSdkVersion,
      oldSidekickCoreVersion: oldSidekickCoreVersion,
      newSidekickCoreVersion: newSidekickCoreVersion,
    );
    template.generate();
  }

  /// Load the sidekick_core dependency from pub.dev
  void pubGet() {
    sidekickDartRuntime.dart(
      ['pub', 'get'],
      workingDirectory: location,
      progress: Progress.printStdErr(),
    );
  }

  /// Execute the update script from the new sidekick_core version
  void executeSidekickUpdate() {
    final script = location.file('bin/update.dart');
    script.verifyExistsOrThrow();

    // Do not change the arguments in a breaking way. The `update_sidekick_cli.dart`
    // script will be called from another sidekick_core version. Changes will break
    // the update process.
    // Only add parameters, never remove any.
    sidekickDartRuntime.dart(
      [
        script.path,
        SidekickContext.cliName,
        oldSidekickCoreVersion.canonicalizedVersion,
        newSidekickCoreVersion.canonicalizedVersion,
      ],
      progress: Progress.print(),
    );
  }
}
