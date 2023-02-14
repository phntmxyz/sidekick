import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';

final addFormatCommand192 = MigrationStep.inline(
  (context) async {
    final mainFile = SidekickContext.sidekickPackage.cliMainFile;
    mainFile.replaceFirst(
      '..addCommand(SidekickCommand())',
      '..addCommand(SidekickCommand())'
          '\n    '
          '..addCommand(FormatCommand())',
    );
  },
  name: 'Add a format command',
  targetVersion: Version(1, 1, 0),
  pullRequestLink: 'github.com/phntmxyz/sidekick/pull/192',
);
