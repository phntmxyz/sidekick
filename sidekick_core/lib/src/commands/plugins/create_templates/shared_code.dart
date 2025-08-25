import 'package:recase/recase.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/plugins/create_templates/plugin_template_generator.dart';

/// This template adds a pub dependency and writes the code of a [Command] into
/// the user's sidekick CLI as well as registers it there.
///
/// The [Command] code is not shared, thus is highly customizable. But it uses
/// shared code from the plugin package that is registered added as dependency.
/// Update of the helper functions is possible via pub, but the actual command
/// flow is up to the user.
class SharedCodeTemplate extends PluginTemplateGenerator {
  const SharedCodeTemplate();
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
        .writeAsStringSync(props.helpers);

    final templateDirectory = pluginDirectory.directory('template')
      ..createSync();
    final pluginCommandTemplateFile = templateDirectory
        .file('commands/${props.commandName.snakeCase}_command.template.dart')
      ..createSync(recursive: true);
    pluginCommandTemplateFile.writeAsStringSync(props.exampleCommand);

    super.generate(props);
  }
}

extension on PluginTemplateProperties {
  String get pubspecTemplate => '''
name: $pluginName
description: Generated sidekick plugin (template shared-code)
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

  await addSelfAsDependency();
  await pubGet(package);
  
  final cliCommandFile =
      package.root.file('lib/src/commands/${commandName.snakeCase}_command.dart');
  cliCommandFile.createSync(recursive: true);

  PluginContext
      .installerPlugin
      .root
      .file('template/commands/${commandName.snakeCase}_command.template.dart')
      .copySync(cliCommandFile.path);
  
  await registerPlugin(
    sidekickCli: package,
    import: "import 'package:\${package.name}/src/commands/${commandName.snakeCase}_command.dart';",
    command: '${commandName.pascalCase}Command()',
  );
}
''';

  String get exampleCommand => '''
${[
        "import 'package:sidekick_core/sidekick_core.dart';",
        "import 'package:$pluginName/${pluginName.snakeCase}.dart';",
      ].sorted().join('\n')}

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
    final hello = getGreetings().shuffled().first;
    print('\$hello from PHNTM!');
    
    final bye = getFarewells().shuffled().first;
    print('\$bye from PHNTM!');
  }
}
''';

  String get helpers => '''
/// Sidekick plugin ${pluginName.titleCase}
library;

List<String> getGreetings() => [
      'Moin',
      'Servus',
      'Ciao',
      'Gruezi',
    ];

List<String> getFarewells() => [
      'Ciao',
      'San Frantschüssko',
      'Hau Rheinland',
      'Tschüsseldorf',
    ];
''';
}
