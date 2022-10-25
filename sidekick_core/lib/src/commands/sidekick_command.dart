import 'package:sidekick_core/sidekick_core.dart';

/// Sidekick CLI tools directly shipped from the sidekick_core package
class SidekickCommand extends Command {
  @override
  final String description = 'Manages the sidekick CLI';

  @override
  final String name = 'sidekick';

  SidekickCommand() {
    addSubcommand(PluginsCommand());
    addSubcommand(RecompileCommand());
    addSubcommand(InstallGlobalCommand());
  }
}
