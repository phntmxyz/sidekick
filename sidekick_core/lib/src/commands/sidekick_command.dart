import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/add_command_command.dart';
import 'package:sidekick_core/src/commands/update_command.dart';

/// Sidekick CLI tools directly shipped from the sidekick_core package
class SidekickCommand extends Command {
  @override
  final String description = 'Manages the sidekick CLI';

  @override
  final String name = 'sidekick';

  SidekickCommand() {
    addSubcommand(PluginsCommand());
    addSubcommand(CreateCommandCommand());
    addSubcommand(RecompileCommand());
    addSubcommand(InstallGlobalCommand());
    addSubcommand(UpdateCommand());
  }
}
