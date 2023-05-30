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
    final currentDartMinVersion = VersionChecker.getMinimumVersionConstraint(
          SidekickContext.sidekickPackage,
          ['environment', 'sdk'],
        ) ??
        Version(2, 19, 0);

    final futureDartSdkVersions = await _dartArchive
        .getLatestDartVersions()
        .where((version) => version >= currentDartMinVersion)
        .toList();

    final futureDartSdkVersionWithLatestPatch = futureDartSdkVersions
        .groupBy((v) => Version(v.major, v.minor, 0))
        .mapEntries((versionGroup) => versionGroup.value.maxBy((v) => v.patch)!)
        .toList();

    final availableVersions = <DartPackageBundle>[];
    for (final dartVersion in futureDartSdkVersionWithLatestPatch) {
      final sidekickCoreVersion =
          await VersionChecker.getLatestDependencyVersion(
        'sidekick_core',
        dartSdkVersion: dartVersion,
      );
      if (sidekickCoreVersion != null) {
        final packageBundle = DartPackageBundle(
          dartSdkVersion: dartVersion,
          sidekickCoreVersion: sidekickCoreVersion,
        );
        availableVersions.add(packageBundle);
      }
    }

    // to remember which sidekick_core version the sidekick CLI was generated
    // with, that sidekick_core version is written into the CLI's pubspec.yaml
    // at the path ['sidekick', 'cli_version']
    final currentSidekickCliVersion =
        VersionChecker.getMinimumVersionConstraint(
              SidekickContext.sidekickPackage,
              ['sidekick', 'cli_version'],
            ) ??
            Version.none;

    final DartPackageBundle packageToInstall;
    if (version != null) {
      // `availableVersions` only contains non-pre-release versions. If a pre-release version is explicitly given, install it nonetheless
      if (!version.isPreRelease &&
          !availableVersions
              .map((e) => e.sidekickCoreVersion)
              .contains(version)) {
        print(
          "'$version' is not a valid/compatible sidekick_core version, "
          "visit https://pub.dev/packages/sidekick_core/versions for more info.",
        );
        return;
      }

      // check whether multiple dart versions are compatible with the given sidekick_core version
      final List<Version> availableDartVersions =
          futureDartSdkVersionWithLatestPatch;

      if (availableDartVersions.length == 1) {
        packageToInstall = DartPackageBundle(
          dartSdkVersion: availableDartVersions.single,
          sidekickCoreVersion: version,
        );
      } else {
        // let user select which Dart version to upgrade to, default latest
        final latestDartVersion = availableDartVersions.max()!;
        print(white('Which Dart version do you want to install?'));
        final dartVersionToInstall = menu(
          prompt: 'Dart version to install',
          options: [...availableDartVersions],
          defaultOption: latestDartVersion,
          format: (Object? option) {
            final version = option! as Version;
            if (version == currentDartMinVersion) {
              return '$version (current)';
            }
            if (version == latestDartVersion) {
              return '$version (latest)';
            }
            return version.toString();
          },
        );
        packageToInstall = DartPackageBundle(
          dartSdkVersion: dartVersionToInstall,
          sidekickCoreVersion: version,
        );
      }
    } else {
      if (availableVersions.isEmpty) {
        print('No compatible sidekick_core version found, '
            'visit https://pub.dev/packages/sidekick_core/versions for more info.');
        return;
      }
      if (availableVersions.length == 1) {
        packageToInstall = availableVersions.first;
      } else {
        final latestPackageBundle = availableVersions
            .sortedBy((e) => e.sidekickCoreVersion)
            .thenBy((e) => e.dartSdkVersion)
            .last;
        print(white('Which versions do you want to install?'));
        packageToInstall = menu(
          prompt: 'Version to install',
          options: [...availableVersions],
          defaultOption: latestPackageBundle,
          format: (Object? option) {
            final packageBundle = option! as DartPackageBundle;
            final packageVersion = packageBundle.sidekickCoreVersion;
            final dartVersion = packageBundle.dartSdkVersion;

            final description = StringBuffer(packageVersion);
            if (packageVersion == currentSidekickCliVersion) {
              description.write(' (current)');
            } else if (packageVersion ==
                latestPackageBundle.sidekickCoreVersion) {
              description.write(' (latest)');
            }

            description.write(' with Dart $dartVersion');
            if (dartVersion == currentDartMinVersion) {
              description.write(' (current)');
            } else if (dartVersion == latestPackageBundle.dartSdkVersion) {
              description.write(' (latest)');
            }

            return description.toString();
          },
        );
      }
    }
    final coreVersionToInstall = packageToInstall.sidekickCoreVersion;
    final dartVersionToInstall = packageToInstall.dartSdkVersion;

    if (coreVersionToInstall <= currentSidekickCliVersion &&
        currentDartMinVersion == dartVersionToInstall) {
      print('No need to update because you are already using the '
          'latest sidekick_core:$currentSidekickCliVersion version for Dart $dartVersionToInstall.');
      return;
    }
    print(
      'Updating sidekick from $currentSidekickCliVersion (Dart $currentDartMinVersion) '
      'to $coreVersionToInstall (Dart $dartVersionToInstall)',
    );

    // Download the new Dart SDK version
    // Update the Dart SDK version in pubspec.yaml, so that the download_dart.sh
    // script can pick up the correct version
    if (currentDartMinVersion != dartVersionToInstall ||
        !sidekickDartRuntime.isDownloaded()) {
      print('Downloading Dart SDK $dartVersionToInstall');
      VersionChecker.updateVersionConstraint(
        package: SidekickContext.sidekickPackage,
        pubspecKeys: ['environment', 'sdk'],
        newMinimumVersion: dartVersionToInstall,
        preferCaret: false,
      );
      sidekickDartRuntime.download();
    }

    if (coreVersionToInstall != currentSidekickCliVersion) {
      final updateName = makeValidPubPackageName(
        'update_${coreVersionToInstall.canonicalizedVersion}',
      );
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
    } else {
      print('Successfully updated the Dart SDK to $dartVersionToInstall.');
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

/// Bundles a Dart version with the corresponding version of a package.
class DartPackageBundle {
  DartPackageBundle({
    required this.dartSdkVersion,
    required this.sidekickCoreVersion,
  });

  final Version dartSdkVersion;
  final Version sidekickCoreVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DartPackageBundle &&
          runtimeType == other.runtimeType &&
          dartSdkVersion == other.dartSdkVersion &&
          sidekickCoreVersion == other.sidekickCoreVersion;

  @override
  int get hashCode => dartSdkVersion.hashCode ^ sidekickCoreVersion.hashCode;

  @override
  String toString() {
    return 'DartPackageBundle{dartSdkVersion: $dartSdkVersion, sidekickCoreVersion: $sidekickCoreVersion}';
  }
}
