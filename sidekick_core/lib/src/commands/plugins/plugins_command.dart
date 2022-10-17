import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/plugins/create_plugin_command.dart';
import 'package:sidekick_core/src/commands/plugins/install_plugin_command.dart';

/// Plugins are extensions for sidekick CLIs that can be installed from pub.dev
class PluginsCommand extends Command {
  @override
  final String description = 'Manages plugins for external commands';

  @override
  final String name = 'plugins';

  PluginsCommand() {
    addSubcommand(InstallPluginCommand());
    addSubcommand(CreatePluginCommand());
  }
}
