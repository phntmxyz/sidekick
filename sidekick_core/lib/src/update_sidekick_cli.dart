import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/update_command.dart';
import 'package:sidekick_core/src/update/migration.dart';
import 'package:sidekick_core/src/update/patches/patch_migrations.dart';
import 'package:sidekick_core/src/version_checker.dart';

/// Updates a sidekick CLI
///
/// This function is called by [UpdateCommand]
/// and receives the following arguments:
///   1. name of the sidekick cli to update
///   2. current version of the sidekick cli
///   3. target version of the sidekick cli
Future<void> main(List<String> args) async {
  // unused but still here for backwards-compatibility
  final sidekickCliName = args[0];
  assert(sidekickCliName.isNotEmpty);
  final currentSidekickCliVersion = Version.parse(args[1]);
  final targetSidekickCoreVersion = Version.parse(args[2]);
  // TODO: verify that the package is named `<cliName>_sidekick`

  print(
    'Updating sidekick CLI ${SidekickContext.cliName} from version '
    '$currentSidekickCliVersion to $targetSidekickCoreVersion ...',
  );

  try {
    // Throws when the migration is aborted due to an error
    await migrate(
      from: currentSidekickCliVersion,
      to: targetSidekickCoreVersion,
      migrations: [
        // Always execute template updates
        UpdateToolsMigration(targetSidekickCoreVersion),
        UpdateEntryPointMigration(targetSidekickCoreVersion),
        UpdateSidekickCoreDependency(targetSidekickCoreVersion),
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
      package: SidekickContext.sidekickPackage,
      pubspecKeys: ['sidekick', 'cli_version'],
      newMinimumVersion: targetSidekickCoreVersion,
      pinVersion: true,
    );
    print(
      green(
        'Successfully updated sidekick CLI ${SidekickContext.cliName} from version $currentSidekickCliVersion to $targetSidekickCoreVersion!',
      ),
    );
  } catch (_) {
    print(
      red(
        'There was an error updating sidekick CLI ${SidekickContext.cliName} from version $currentSidekickCliVersion to $targetSidekickCoreVersion.',
      ),
    );
    rethrow;
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
      name: SidekickContext.sidekickPackage.cliName,
      entrypointLocation: SidekickContext.entryPoint,
      packageLocation: SidekickContext.sidekickPackage.root,
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
      name: SidekickContext.sidekickPackage.cliName,
      entrypointLocation: SidekickContext.entryPoint,
      packageLocation: SidekickContext.sidekickPackage.root,
    );
    template.generateEntrypoint(props);
  }
}

/// Updates the sidekick_core dependency in pubspec.yaml
class UpdateSidekickCoreDependency extends MigrationStep {
  UpdateSidekickCoreDependency(Version targetVersion)
      : super(
          name: 'Update sidekick_core dependency',
          targetVersion: targetVersion,
        );

  @override
  Future<void> migrate(MigrationContext context) async {
    VersionChecker.updateVersionConstraint(
      package: SidekickContext.sidekickPackage,
      pubspecKeys: ['dependencies', 'sidekick_core'],
      newMinimumVersion: targetVersion,
    );
  }
}
