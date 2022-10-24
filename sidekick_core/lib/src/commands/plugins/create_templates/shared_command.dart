import 'package:recase/recase.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/plugins/create_templates/template_generator.dart';

/// This template adds a pub dependency to a shared CLI [Command] and registers
/// it in the user's sidekick CLI.
///
/// This method is designed for cases where the command might be configurable
/// with parameters but doesn't allow users to actually change the code.
///
/// It allows updates (via `pub upgrade`) without users having to touch their code.
class SharedCommandTemplate extends TemplateGenerator {
  const SharedCommandTemplate();

  @override
  void generate(TemplateProperties props) {
    final pluginDirectory = props.pluginDirectory;
    pluginDirectory
        .file('pubspec.yaml')
        .writeAsStringSync(props.pubspecTemplate);

    final toolDirectory = pluginDirectory.directory('tool')..createSync();
    toolDirectory.file('install.dart').writeAsStringSync(props.installTemplate);

    final libDirectory = pluginDirectory.directory('lib')..createSync();
    libDirectory
        .file('${props.pluginName.snakeCase}_command.dart')
        .writeAsStringSync(props.exampleCommand);

    super.generate(props);
  }
}

extension on TemplateProperties {
  String get pubspecTemplate => '''
name: $pluginName
description: Generated sidekick plugin (template shared-command)
version: 0.0.1

environment:
  sdk: '>=2.14.0 <3.0.0'

dependencies:
  sidekick_core: '>=0.7.1 <1.0.0'

dev_dependencies:
  sidekick_plugin_installer: ^0.1.3
  lint: ^1.5.0
''';

  String get installTemplate => '''
import 'package:sidekick_core/sidekick_core.dart'
    hide cliName, repository, mainProject;
import 'package:sidekick_plugin_installer/sidekick_plugin_installer.dart';

Future<void> main() async {
  final SidekickPackage package = PluginContext.sidekickPackage;

  if (PluginContext.localPlugin == null) {
    pubAddDependency(package, '${pluginName.snakeCase}');
  } else {
    // For local development
    pubAddLocalDependency(package, PluginContext.localPlugin!.root.path);
  }
  pubGet(package);

  registerPlugin(
    sidekickCli: package,
    import: "import 'package:$pluginName/${pluginName.snakeCase}_command.dart';",
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
