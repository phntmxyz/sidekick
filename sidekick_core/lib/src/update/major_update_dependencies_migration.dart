import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';

/// Updates all dependencies to their latest major version
class MajorUpdateDependenciesMigration extends MigrationStep {
  MajorUpdateDependenciesMigration(Version targetVersion)
      : super(name: 'Major update dependencies', targetVersion: targetVersion);

  @override
  Future<void> migrate(MigrationContext context) async {
    await sidekickDartRuntime.dart(
      ['pub', 'upgrade', '--major-versions'],
      workingDirectory: SidekickContext.sidekickPackage.root,
    );
  }
}
