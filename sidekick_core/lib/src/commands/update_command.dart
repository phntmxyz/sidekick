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

  // only used for debug logging in case of an error. Never store data here to retrive it later!
  final _gatheredInformation = <String, String>{};

  @override
  Future<void> run() async {
    try {
      await _runInternal();
    } catch (e, s) {
      printerr(
        red('Error while updating sidekick CLI: $e\n'
            'Stack trace: $s\n\n'
            'This is all information gathered during the update process\n'
            '${_gatheredInformation.entries.map((e) => '${e.key.padLeft(32)}: ${e.value}').join('\n')}'),
      );
      _gatheredInformation.clear();
      rethrow;
    }
  }

  Future<void> _runInternal() async {
    final args = argResults!;

    final Version? version = args.versionFromRest(
      formatError: (rest) {
        usageException("'$rest' is not a valid semver version.");
      },
    );
    if (version != null) {
      _gatheredInformation['version argument'] = version.toString();
    }

    // Start from current sdk version, we don't want to downgrade
    final currentDartMinVersion = VersionChecker.getMinimumVersionConstraint(
          SidekickContext.sidekickPackage,
          ['environment', 'sdk'],
        ) ??
        Version(2, 19, 0);
    _gatheredInformation['current Dart SDK version'] =
        currentDartMinVersion.toString();

    final futureDartSdkVersions = await _dartArchive
        .getLatestDartVersions()
        .where((version) => version >= currentDartMinVersion)
        .toList();
    _gatheredInformation['future Dart SDK versions'] =
        futureDartSdkVersions.map((e) => e.toString()).join(', ');

    final futureDartSdkVersionWithLatestPatch = futureDartSdkVersions
        .groupBy((v) => Version(v.major, v.minor, 0))
        .mapEntries((versionGroup) => versionGroup.value.maxBy((v) => v.patch)!)
        .toList();
    _gatheredInformation['future Dart SDK versions with latest patch'] =
        futureDartSdkVersionWithLatestPatch.map((e) => e.toString()).join(', ');

    final availableVersionBundles = await _buildAvailableVersions(
      futureDartSdkVersionWithLatestPatch: futureDartSdkVersionWithLatestPatch,
      version: version,
    );

    // to remember which sidekick_core version the sidekick CLI was generated
    // with, that sidekick_core version is written into the CLI's pubspec.yaml
    // at the path ['sidekick', 'cli_version']
    final currentSidekickCliVersion =
        VersionChecker.getMinimumVersionConstraint(
              SidekickContext.sidekickPackage,
              ['sidekick', 'cli_version'],
            ) ??
            Version.none;
    _gatheredInformation['current sidekick_core version'] =
        currentSidekickCliVersion.toString();

    final packageToInstall = await _selectPackageToInstall(
      availableVersionBundles: availableVersionBundles,
      preselectedSidekickVersion: version,
      currentSidekickCliVersion: currentSidekickCliVersion,
      currentDartMinVersion: currentDartMinVersion,
    );
    if (packageToInstall == null) return;

    final coreVersionToInstall = packageToInstall.sidekickCoreVersion;
    final dartVersionToInstall = packageToInstall.dartSdkVersion;
    _gatheredInformation['dart version to install'] =
        dartVersionToInstall.toString();
    _gatheredInformation['sidekick_core version to install'] =
        coreVersionToInstall.toString();

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

    await _downloadAndUpdate(
      currentDartMinVersion: currentDartMinVersion,
      dartVersionToInstall: dartVersionToInstall,
      currentSidekickCliVersion: currentSidekickCliVersion,
      sidekickVersionToInstall: coreVersionToInstall,
    );
  }

  Future<List<DartPackageBundle>> _buildAvailableVersions({
    required List<Version> futureDartSdkVersionWithLatestPatch,
    required Version? version,
  }) async {
    final availableVersions = <DartPackageBundle>[];

    for (final dartVersion in futureDartSdkVersionWithLatestPatch) {
      if (version != null) {
        // When a specific version is requested, check if that version is compatible with this Dart SDK
        final isCompatible =
            await VersionChecker.isPackageVersionCompatibleWithDartSdk(
          dependency: 'sidekick_core',
          packageVersion: version,
          dartSdkVersion: dartVersion,
        );

        if (isCompatible) {
          final packageBundle = DartPackageBundle(
            dartSdkVersion: dartVersion,
            sidekickCoreVersion: version,
          );

          // Apply compatibility filters
          if (_isDcliIncompatible(version, dartVersion)) {
            continue;
          }

          availableVersions.add(packageBundle);
        }
      } else {
        // When no specific version is requested, use the original logic to find latest compatible versions
        final sidekickCoreVersion =
            await VersionChecker.getLatestDependencyVersion(
          'sidekick_core',
          dartSdkVersion: dartVersion,
          preRelease: version?.isPreRelease ?? false,
        );
        if (sidekickCoreVersion != null) {
          final packageBundle = DartPackageBundle(
            dartSdkVersion: dartVersion,
            sidekickCoreVersion: sidekickCoreVersion,
          );

          // Apply compatibility filters
          if (_isDcliIncompatible(sidekickCoreVersion, dartVersion)) {
            continue;
          }

          availableVersions.add(packageBundle);
        }
      }
    }
    _gatheredInformation['available sidekick_core versions'] =
        availableVersions.map((e) => e.toString()).join(', ');

    return availableVersions;
  }

  /// Checks if a sidekick_core version is incompatible with a Dart SDK version
  /// due to dcli's waitFor compatibility issues.
  bool _isDcliIncompatible(Version sidekickCoreVersion, Version dartVersion) {
    if (sidekickCoreVersion < Version(2, 999, 0) &&
        dartVersion >= Version(3, 3, 0)) {
      // sidekick_core: 2.X is not compatible with Dart SDK 3.3.0+, because dcli:<4.x is not
      // compatible with Dart SDK 3.3.0 anymore
      // Dart 3.3.0 waitFor requires --enable_deprecated_wait_for in the VM
      // Dart 3.4.0 waitFor was removed
      // Starting with sidekick_core: 3.x (and dcli: 4.0.0) newer Dart SDKs can be used
      return true;
    }
    return false;
  }

  Future<DartPackageBundle?> _selectPackageToInstall({
    required List<DartPackageBundle> availableVersionBundles,
    required Version? preselectedSidekickVersion,
    required Version currentSidekickCliVersion,
    required Version currentDartMinVersion,
  }) async {
    // Handle preselected version
    if (preselectedSidekickVersion != null) {
      return await _selectWithPreselectedVersion(
        availableVersionBundles: availableVersionBundles,
        preselectedVersion: preselectedSidekickVersion,
        currentDartMinVersion: currentDartMinVersion,
      );
    }

    // Handle auto-selection (no version specified)
    return await _selectLatestVersion(
      availableVersionBundles: availableVersionBundles,
      currentSidekickCliVersion: currentSidekickCliVersion,
      currentDartMinVersion: currentDartMinVersion,
    );
  }

  Future<DartPackageBundle?> _selectWithPreselectedVersion({
    required List<DartPackageBundle> availableVersionBundles,
    required Version preselectedVersion,
    required Version currentDartMinVersion,
  }) async {
    final isVersionMissing = availableVersionBundles.none(
      (bundle) => bundle.sidekickCoreVersion == preselectedVersion,
    );

    if (isVersionMissing && !preselectedVersion.isPreRelease) {
      print(
          "'$preselectedVersion' is not a valid/compatible sidekick_core version, "
          "visit https://pub.dev/packages/sidekick_core/versions for more info.");
      return null;
    }

    // If only one option, use it
    if (availableVersionBundles.length == 1) {
      return availableVersionBundles.first;
    }

    // Handle multiple options - let user choose Dart version
    final availableDartVersions =
        availableVersionBundles.map((bundle) => bundle.dartSdkVersion).toList();

    // Handle no compatible Dart versions
    if (availableDartVersions.isEmpty) {
      return _handleNoCompatibleVersions(
        preselectedVersion,
        currentDartMinVersion,
      );
    }

    // Let user select Dart version
    final selectedDartVersion = await _selectDartVersion(
      availableDartVersions: availableDartVersions,
      currentDartMinVersion: currentDartMinVersion,
    );

    return DartPackageBundle(
      dartSdkVersion: selectedDartVersion,
      sidekickCoreVersion: preselectedVersion,
    );
  }

  Future<DartPackageBundle?> _selectLatestVersion({
    required List<DartPackageBundle> availableVersionBundles,
    required Version currentSidekickCliVersion,
    required Version currentDartMinVersion,
  }) async {
    if (availableVersionBundles.isEmpty) {
      print('No compatible sidekick_core version found, '
          'visit https://pub.dev/packages/sidekick_core/versions for more info.');
      return null;
    }

    if (availableVersionBundles.length == 1) {
      return availableVersionBundles.first;
    }

    // Let user select from all available bundles
    final latestBundle = availableVersionBundles
        .sortedBy((bundle) => bundle.sidekickCoreVersion)
        .thenBy((bundle) => bundle.dartSdkVersion)
        .last;

    print(white('Which versions do you want to install?'));
    return menu(
      'Version to install',
      options: [...availableVersionBundles],
      defaultOption: latestBundle,
      format: (option) => _formatPackageBundle(
        (option as DartPackageBundle?)!,
        currentSidekickCliVersion: currentSidekickCliVersion,
        currentDartMinVersion: currentDartMinVersion,
        latestBundle: latestBundle,
      ),
    );
  }

  DartPackageBundle? _handleNoCompatibleVersions(
    Version preselectedVersion,
    Version currentDartMinVersion,
  ) {
    // For preview versions, allow fallback to current Dart SDK
    if (preselectedVersion.isPreRelease) {
      return DartPackageBundle(
        dartSdkVersion: currentDartMinVersion,
        sidekickCoreVersion: preselectedVersion,
      );
    }

    print(
      'No compatible Dart SDK versions found for the requested sidekick_core version.',
    );
    return null;
  }

  Future<Version> _selectDartVersion({
    required List<Version> availableDartVersions,
    required Version currentDartMinVersion,
  }) async {
    final latestDartVersion = availableDartVersions.max()!;

    _gatheredInformation['available Dart versions for requested version'] =
        availableDartVersions.map((v) => v.toString()).join(', ');
    _gatheredInformation['latest Dart version for requested version'] =
        latestDartVersion.toString();

    print(white('Which Dart version do you want to install?'));
    return menu(
      'Dart version to install',
      options: [...availableDartVersions],
      defaultOption: latestDartVersion,
      format: (option) => _formatDartVersion(
        option as Version,
        currentDartMinVersion: currentDartMinVersion,
        latestDartVersion: latestDartVersion,
      ),
    );
  }

  String _formatDartVersion(
    Version version, {
    required Version currentDartMinVersion,
    required Version latestDartVersion,
  }) {
    if (version == currentDartMinVersion) return '$version (current)';
    if (version == latestDartVersion) return '$version (latest)';
    return version.toString();
  }

  String _formatPackageBundle(
    DartPackageBundle bundle, {
    required Version currentSidekickCliVersion,
    required Version currentDartMinVersion,
    required DartPackageBundle latestBundle,
  }) {
    final description = StringBuffer(bundle.sidekickCoreVersion);

    if (bundle.sidekickCoreVersion == currentSidekickCliVersion) {
      description.write(' (current)');
    } else if (bundle.sidekickCoreVersion == latestBundle.sidekickCoreVersion) {
      description.write(' (latest)');
    }

    description.write(' with Dart ${bundle.dartSdkVersion}');

    if (bundle.dartSdkVersion == currentDartMinVersion) {
      description.write(' (current)');
    } else if (bundle.dartSdkVersion == latestBundle.dartSdkVersion) {
      description.write(' (latest)');
    }

    return description.toString();
  }

  Future<void> _downloadAndUpdate({
    required Version currentDartMinVersion,
    required Version dartVersionToInstall,
    required Version currentSidekickCliVersion,
    required Version sidekickVersionToInstall,
  }) async {
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

    if (sidekickVersionToInstall != currentSidekickCliVersion) {
      final updateName = makeValidPubPackageName(
        'update_${sidekickVersionToInstall.canonicalizedVersion}',
      );
      final updateScriptDir =
          SidekickContext.sidekickPackage.buildDir.directory(updateName);

      final executor = UpdateExecutor(
        location: updateScriptDir,
        oldSidekickCoreVersion: currentSidekickCliVersion,
        newSidekickCoreVersion: sidekickVersionToInstall,
        dartSdkVersion: dartVersionToInstall,
      );

      try {
        // Write update package with just the updated sidekick_core dependency and the chosen Dart SDK version
        // This prevents any version conflicts and the entire sidekick update will
        // be executed from the new sidekick_core version and can be updated.
        executor.generateUpdatePackage();

        // Execute the update script of the new sidekick_core version with the new Dart SDK version
        await executor.pubGet();
        await executor.executeSidekickUpdate();
      } finally {
        // cleanup
        updateScriptDir.deleteSync(recursive: true);
      }
    } else {
      print('Successfully updated the Dart SDK to $dartVersionToInstall.');
    }

    // Run pub get on cli package to download the new sidekick_core version
    // (sidekick_core was updated by the update script)
    await _dartCommand(
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
Future<void> Function(
  List<String> args, {
  Progress? progress,
  Directory? workingDirectory,
  bool nothrow,
}) get _dartCommand {
  if (sidekickDartRuntime.isDownloaded()) {
    return sidekickDartRuntime.dart;
  } else {
    return dart;
  }
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
  Future<void> pubGet() async {
    await sidekickDartRuntime.dart(
      ['pub', 'get'],
      workingDirectory: location,
      progress: Progress.printStdErr(),
    );
  }

  /// Execute the update script from the new sidekick_core version
  Future<void> executeSidekickUpdate() async {
    final script = location.file('bin/update.dart');
    script.verifyExistsOrThrow();

    // Do not change the arguments in a breaking way. The `update_sidekick_cli.dart`
    // script will be called from another sidekick_core version. Changes will break
    // the update process.
    // Only add parameters, never remove any.
    await sidekickDartRuntime.dart(
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
