import 'package:args/command_runner.dart';
// ignore: implementation_imports
import 'package:sidekick_core/src/commands/plugins/create_plugin_command.dart';

/// Bundles creation templates of plugins
class PluginsCommand extends Command {
  @override
  final String description = 'Manages plugins for external commands';

  @override
  final String name = 'plugins';

  PluginsCommand() {
    addSubcommand(CreatePluginCommand());
  }
}
