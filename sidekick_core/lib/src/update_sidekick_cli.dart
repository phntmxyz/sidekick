import 'package:pub_semver/pub_semver.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/update_command.dart';
import 'package:sidekick_core/src/update/migration.dart';
import 'package:sidekick_core/src/update/patches/patch_migrations.dart';
import 'package:sidekick_core/src/version_checker.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Updates a sidekick CLI
///
/// This function is called by [UpdateCommand]
/// and receives the following arguments:
///   1. name of the sidekick cli to update
///   2. current version of the sidekick cli
///   3. target version of the sidekick cli
Future<void> main(List<String> args) async {
  final sidekickCliName = args[0];
  final currentSidekickCliVersion = Version.parse(args[1]);
  final targetSidekickCoreVersion = Version.parse(args[2]);


  // TODO: verify that the package is named `<cliName>_sidekick`

  print(
    'Updating sidekick CLI $sidekickCliName from version '
    '$currentSidekickCliVersion to $targetSidekickCoreVersion ...',
  );

  /// Creating a runner to allow access to values like [repository], [mainProject] or [cliName]
  final runner = initializeSidekick(name: sidekickCliName);
  final unmount = runner.mount();
  try {
    // Throws when the migration is aborted due to an error
    await migrate(
      from: currentSidekickCliVersion,
      to: targetSidekickCoreVersion,
      migrations: [
        // Always execute template updates
        UpdateToolsMigration(targetSidekickCoreVersion),
        UpdateEntryPointMigration(targetSidekickCoreVersion),
        // Always check for latest stable dart version
        UseLatestDartVersionMigration(targetSidekickCoreVersion),
        // Migration steps from git patches
        ...patchMigrations,
      ],
      onMigrationStepStart: (context) {
        print(' - ${context.step.name}');
      },
      onMigrationStepError: (context) {
        printerr('Migration failed: ${context.step.name}');
        printerr(context.exception?.toString());

        // Migrations from git patches are likely to fail (e.g. if the user
        // already modified their sidekick CLI)
        // Therefore git patch migrations are skipped by default,
        // the printed error contains instructions to check the patch and
        // apply it manually if necessary
        if (context.step is GitPatchMigrationStep) {
          return MigrationErrorHandling.skip;
        }

        printerr(context.stackTrace.toString());
        // TODO make errors interactive and allow skipping
        return MigrationErrorHandling.abort;
      },
    );

    // update sidekick: cli_version: <version> in pubspec.yaml to signalize
    // that update has completed successfully
    VersionChecker.updateVersionConstraint(
      package: Repository.requiredSidekickPackage,
      pubspecKeys: ['sidekick', 'cli_version'],
      newMinimumVersion: targetSidekickCoreVersion,
      pinVersion: true,
    );
    print(
      green(
        'Successfully updated sidekick CLI $cliName from version $currentSidekickCliVersion to $targetSidekickCoreVersion!',
      ),
    );
  } catch (_) {
    print(
      red(
        'There was an error updating sidekick CLI $cliName from version $currentSidekickCliVersion to $targetSidekickCoreVersion.',
      ),
    );
    rethrow;
  } finally {
    unmount();
  }
}

/// Updates the /tool directory
class UpdateToolsMigration extends MigrationStep {
  UpdateToolsMigration(Version targetVersion)
      : super(
          name: 'Update /tool directory',
          targetVersion: targetVersion,
        );

  @override
  Future<void> migrate(MigrationContext context) async {
    final template = SidekickTemplate();
    final props = SidekickTemplateProperties(
      name: Repository.requiredSidekickPackage.cliName,
      entrypointLocation: Repository.requiredEntryPoint,
      packageLocation: Repository.requiredCliPackage,
    );
    template.generateTools(props);
  }
}

/// Updates the cli entrypoint bash script
class UpdateEntryPointMigration extends MigrationStep {
  UpdateEntryPointMigration(Version targetVersion)
      : super(
          name: 'Update entrypoint',
          targetVersion: targetVersion,
        );

  @override
  Future<void> migrate(MigrationContext context) async {
    final template = SidekickTemplate();
    final props = SidekickTemplateProperties(
      name: Repository.requiredSidekickPackage.cliName,
      entrypointLocation: Repository.requiredEntryPoint,
      packageLocation: Repository.requiredCliPackage,
    );
    template.generateEntrypoint(props);
  }
}

/// Update the embedded dart sdk to the latest stable version
class UseLatestDartVersionMigration extends MigrationStep {
  UseLatestDartVersionMigration(Version targetVersion)
      : super(
          name: 'Update embedded dart version',
          targetVersion: targetVersion,
        );

  @override
  Future<void> migrate(MigrationContext context) async {
    final package = Repository.requiredSidekickPackage;

    final pubspec = YamlEditor(package.pubspec.readAsStringSync());
    final String? sdkConstraints =
        pubspec.parseAt(['environment', 'sdk']).value as String?;
    final currentDartVersion = () {
      try {
        final range = VersionConstraint.parse(sdkConstraints!) as VersionRange;
        return range.min;
      } catch (_) {
        return null;
      }
    }();

    if (currentDartVersion == null) {
      throw 'Could not find dart version pubspec.yaml (environment.sdk)';
    }
    var latestDartVersion = await VersionChecker.getLatestStableDartVersion();

    if (latestDartVersion >= Version(3, 0, 0)) {
      // Do not upgrade to Dart 3 unless explicitly enabled
      // fallback to latest 2.x version
      latestDartVersion = Version(2, 19, 0);
    }

    if (currentDartVersion >= latestDartVersion) {
      // Already using latest dart version
      return;
    }

    // Update dart version to latest stable
    pubspec.update(
      ['environment', 'sdk'],
      '>=$latestDartVersion <${latestDartVersion.nextMajor}',
    );
    package.pubspec.writeAsStringSync(pubspec.toString());
  }
}
