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
        .file('${props.pluginName.snakeCase}_command.template.dart')
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

  addDependencyNonBreakingWrapper();
  pubGet(package);
  
  final cliCommandFile =
      package.root.file('lib/src/${pluginName.snakeCase}_command.dart');

  PluginContext
      .installerPlugin
      .root
      .file('template/${pluginName.snakeCase}_command.template.dart')
      .copySync(cliCommandFile.path);
  
  registerPlugin(
    sidekickCli: package,
    import: "import 'package:\${package.name}/src/${pluginName.snakeCase}_command.dart';",
    command: '${pluginName.pascalCase}Command()',
  );
}
''';

  String get exampleCommand => '''
${[
        "import 'package:sidekick_core/sidekick_core.dart';",
        "import 'package:$pluginName/${pluginName.snakeCase}.dart';",
      ].sorted().join('\n')}

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
    final hello = getGreetings().shuffled().first;
    print('\$hello from PHNTM!');
    
    final bye = getFarewells().shuffled().first;
    print('\$bye from PHNTM!');
  }
}
''';

  String get helpers => '''
library ${pluginName.snakeCase};

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
