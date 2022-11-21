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
    srcDir
        .file('${props.commandName.snakeCase}_command.dart')
        .writeAsStringSync(props.exampleCommand);

    super.generate(props);
  }
}

extension on PluginTemplateProperties {
  String get pubspecTemplate => '''
name: $pluginName
description: Generated sidekick plugin (template shared-command)
version: 0.0.1

environment:
  sdk: '>=2.14.0 <3.0.0'

dependencies:
  sidekick_core: '>=0.7.1 <1.0.0'

dev_dependencies:
  lint: ^1.5.0
  sidekick_plugin_installer: ^0.1.3
''';

  String get installTemplate => '''
import 'package:sidekick_core/sidekick_core.dart'
    hide cliName, repository, mainProject;
import 'package:sidekick_plugin_installer/sidekick_plugin_installer.dart';

Future<void> main() async {
  final SidekickPackage package = PluginContext.sidekickPackage;

  addDependency(
    package: PluginContext.sidekickPackage,
    dependency: PluginContext.name,
    versionConstraint: PluginContext.versionConstraint,
    localPath: PluginContext.localPath,
    hostedUrl: PluginContext.hostedUrl,
    gitUrl: PluginContext.gitUrl,
    gitRef: PluginContext.gitRef,
    gitPath: PluginContext.gitPath,
  );
  pubGet(package);

  registerPlugin(
    sidekickCli: package,
    import: "import 'package:$pluginName/${pluginName.snakeCase}.dart';",
    command: '${pluginName.pascalCase}Command()',
  );
}
''';

  String get library => '''
library ${pluginName.snakeCase};

export 'package:${pluginName.snakeCase}/src/${commandName.snakeCase}_command.dart';
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
