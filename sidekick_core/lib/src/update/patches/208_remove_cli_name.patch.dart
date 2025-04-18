import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';

final fixUsageMessage208 = MigrationStep.inline(
  (context) {
    final mainFile = SidekickContext.sidekickPackage.cliMainFile;
    mainFile.replaceFirst("    name: '${SidekickContext.cliName}',\n", '');
  },
  name: 'Remove deprecated cli name',
  targetVersion: Version(1, 0, 0),
  pullRequestLink: 'github.com/phntmxyz/sidekick/pull/208',
);
