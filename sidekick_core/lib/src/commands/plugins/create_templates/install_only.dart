import 'package:recase/recase.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/plugins/create_templates/plugin_template_generator.dart';

/// This template is the very minimum, featuring just a tool/install.dart file
/// that writes all code to be installed into the users sidekick CLI.
///
/// It doesn't add a pub dependency with shared code. All code is generated in
/// the users sidekick CLI, being fully adjustable.
class InstallOnlyTemplate extends PluginTemplateGenerator {
  const InstallOnlyTemplate();

  @override
  void generate(PluginTemplateProperties props) {
    final pluginDirectory = props.pluginDirectory;
    pluginDirectory
        .file('pubspec.yaml')
        .writeAsStringSync(props.pubspecTemplate);

    final toolDirectory = pluginDirectory.directory('tool')..createSync();
    toolDirectory.file('install.dart').writeAsStringSync(props.installTemplate);

    super.generate(props);
  }
}

extension on PluginTemplateProperties {
  String get pubspecTemplate => '''
name: $pluginName
description: Generated sidekick plugin (template install-only)
version: 0.0.1

environment:
  sdk: '>=2.14.0 <3.0.0'

dependencies:
  sidekick_core: ^1.0.0

dev_dependencies:
  lint: ^1.5.0
  sidekick_plugin_installer: ^0.3.0
''';

  String get installTemplate => '''
import 'package:sidekick_core/sidekick_core.dart'
    hide cliName, repository, mainProject;
import 'package:sidekick_plugin_installer/sidekick_plugin_installer.dart';

Future<void> main() async {
  final SidekickPackage package = PluginContext.sidekickPackage;

  final commandFile = package.root.file('lib/src/${pluginName.snakeCase}.dart');
  commandFile.writeAsStringSync("""
$exampleCommand
""");

  registerPlugin(
    sidekickCli: package,
    import: "import 'package:\${package.name}/src/${pluginName.snakeCase}.dart';",
    command: '${pluginName.pascalCase}Command()',
  );
}
''';

  String get exampleCommand => '''
import 'package:sidekick_core/sidekick_core.dart';

class ${pluginName.pascalCase}Command extends Command {
  @override
  final String description = 'Sample command';

  @override
  final String name = '${pluginName.paramCase}';

  ${pluginName.pascalCase}Command() {
    // add parameters here with argParser.addOption
  }

  @override
  Future<void> run() async {
    // please implement me
    print('Greetings from PHNTM!');
  }
}
''';
}
