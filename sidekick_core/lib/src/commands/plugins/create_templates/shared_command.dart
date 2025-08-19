import 'package:recase/recase.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/plugins/create_templates/plugin_template_generator.dart';

/// This template adds a pub dependency to a shared CLI [Command] and registers
/// it in the user's sidekick CLI.
///
/// This method is designed for cases where the command might be configurable
/// with parameters but doesn't allow users to actually change the code.
///
/// It allows updates (via `pub upgrade`) without users having to touch their code.
class SharedCommandTemplate extends PluginTemplateGenerator {
  const SharedCommandTemplate();

  @override
  void generate(PluginTemplateProperties props) {
    final pluginDirectory = props.pluginDirectory;
    pluginDirectory
        .file('pubspec.yaml')
        .writeAsStringSync(props.pubspecTemplate);

    final toolDirectory = pluginDirectory.directory('tool')..createSync();
    toolDirectory.file('install.dart').writeAsStringSync(props.installTemplate);

    final libDirectory = pluginDirectory.directory('lib')..createSync();
    libDirectory
        .file('${props.pluginName.snakeCase}.dart')
        .writeAsStringSync(props.library);

    final srcDir = libDirectory.directory('src')..createSync();
    final commandFile =
        srcDir.file('commands/${props.commandName.snakeCase}_command.dart');
    commandFile
      ..createSync(recursive: true)
      ..writeAsStringSync(props.exampleCommand);

    super.generate(props);
  }
}

extension on PluginTemplateProperties {
  String get pubspecTemplate => '''
name: $pluginName
description: Generated sidekick plugin (template shared-command)
version: 0.0.1
topics:
  - sidekick
  - cli
  - sidekick-plugin

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  sidekick_core: ^3.0.0

dev_dependencies:
  lint: ^2.0.0
  sidekick_plugin_installer: ^2.0.0
''';

  String get installTemplate => '''
import 'package:sidekick_core/sidekick_core.dart'
    hide cliName, mainProject, repository;
import 'package:sidekick_plugin_installer/sidekick_plugin_installer.dart';

Future<void> main() async {
  final SidekickPackage package = PluginContext.sidekickPackage;

  addSelfAsDependency();
  pubGet(package);

  registerPlugin(
    sidekickCli: package,
    import: "import 'package:$pluginName/$pluginName.dart';",
    command: '${commandName.pascalCase}Command()',
  );
}
''';

  String get library => '''
/// Sidekick plugin ${pluginName.titleCase}
library;

export 'package:${pluginName.snakeCase}/src/commands/${commandName.snakeCase}_command.dart';
''';

  String get exampleCommand => '''
import 'package:sidekick_core/sidekick_core.dart';

class ${commandName.pascalCase}Command extends Command {
  @override
  final String description = 'Sample command';

  @override
  final String name = '$commandName';

  ${commandName.pascalCase}Command() {
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
