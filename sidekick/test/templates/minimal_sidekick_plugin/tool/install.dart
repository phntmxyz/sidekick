import 'package:sidekick_core/sidekick_core.dart'
    hide cliName, repository, mainProject;
import 'package:sidekick_plugin_installer/sidekick_plugin_installer.dart';

Future<void> main() async {
  final SidekickPackage package = PluginContext.sidekickPackage;

  final commandFile = package.root.file('lib/src/minimal_sidekick_plugin.dart');
  commandFile.writeAsStringSync("""
import 'package:sidekick_core/sidekick_core.dart';

class MinimalSidekickPluginCommand extends Command {
  @override
  final String description = 'Sample command';

  @override
  final String name = 'minimal-sidekick-plugin';

  MinimalSidekickPluginCommand() {
    // add parameters here with argParser.addOption
  }

  @override
  Future<void> run() async {
    // please implement me
    print('Greetings from PHNTM!');
  }
}""");

  registerPlugin(
    sidekickCli: package,
    import:
        "import 'package:${package.name}/src/minimal_sidekick_plugin.dart';",
    command: 'MinimalSidekickPluginCommand()',
  );
}
