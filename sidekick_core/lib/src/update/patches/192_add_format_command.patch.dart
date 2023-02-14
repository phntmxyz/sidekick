import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';

final addFormatCommand192 = MigrationStep.inline(
  (context) async {
    final mainFile = SidekickContext.sidekickPackage.cliMainFile;
    final mainFileContent = mainFile.readAsLinesSync();
    mainFileContent.insert(
      mainFileContent.indexWhere((line) => line.contains('runner')) + 1,
      "    ..addCommand(FormatCommand())",
    );
  },
  name: 'Add a format command',
  targetVersion: Version(1, 1, 0),
  pullRequestLink: 'github.com/phntmxyz/sidekick/pull/192',
);
