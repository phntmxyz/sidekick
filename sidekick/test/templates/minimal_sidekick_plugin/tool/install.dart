import 'package:sidekick_core/sidekick_core.dart'
    hide cliName, repository, mainProject;
import 'package:sidekick_plugin_installer/sidekick_plugin_installer.dart';

Future<void> main() async {
  final SidekickPackage package = PluginContext.sidekickPackage;

  addSelfAsDependency();
  pubGet(package);

  final cliCommandFile =
      package.root.file('lib/src/minimal_sidekick_plugin_command.dart');

  PluginContext.installerPlugin.root
      .file('template/minimal_sidekick_plugin_command.template.dart')
      .copySync(cliCommandFile.path);

  registerPlugin(
    sidekickCli: package,
    import:
        "import 'package:${package.name}/src/minimal_sidekick_plugin_command.dart';",
    command: 'MinimalSidekickPluginCommand()',
  );
}
