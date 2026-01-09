import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/update/migration.dart';

final addTestCommand278 = MigrationStep.inline(
  (context) {
    final mainFile = SidekickContext.sidekickPackage.cliMainFile;
    final content = mainFile.readAsStringSync();

    if (content.contains('..addCommand(TestCommand(')) {
      throw 'Test command already exists in ${mainFile.path}';
    }

    // Add TestCommand after FormatCommand if it exists, otherwise after SidekickCommand
    if (content.contains('..addCommand(FormatCommand())')) {
      mainFile.replaceFirst(
        '..addCommand(FormatCommand())',
        '..addCommand(FormatCommand())'
            '\n    '
            '..addCommand(TestCommand())',
      );
    } else if (content.contains('..addCommand(SidekickCommand())')) {
      mainFile.replaceFirst(
        '..addCommand(SidekickCommand())',
        '..addCommand(SidekickCommand())'
            '\n    '
            '..addCommand(TestCommand())',
      );
    } else {
      throw 'Could not find a suitable location to add TestCommand in ${mainFile.path}';
    }
  },
  name: 'Add a test command',
  targetVersion: Version(3, 1, 0),
  pullRequestLink: 'github.com/phntmxyz/sidekick/pull/278',
);
