import 'package:recase/recase.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/plugins/create_templates/template_generator.dart';

/// This template adds a pub dependency and writes the code of a [Command] into
/// the user's sidekick CLI
///
/// The [Command] code is not shared, thus is highly customizable. But it uses
/// shared code from the plugin package that is registered added as dependency.
/// Update of the helper functions is possible via pub, but the actual command
/// flow is up to the user.
class SharedCodeTemplate extends TemplateGenerator {
  const SharedCodeTemplate();
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
        .file('${props.pluginName.snakeCase}.dart')
        .writeAsStringSync(props.helpers);
  }
}

extension on TemplateProperties {
  String get pubspecTemplate => '''
name: $pluginName
description: Generated sidekick plugin (template shared-code)
version: 0.0.1

environment:
  sdk: '>=2.14.0 <3.0.0'

dependencies:

dev_dependencies:
  sidekick_plugin_installer:
''';

  String get installTemplate => '''
import 'package:sidekick_core/sidekick_core.dart'
    hide cliName, repository, mainProject;
import 'package:sidekick_plugin_installer/sidekick_plugin_installer.dart';

Future<void> main(List<String> args) async {
  // The installer injects the path to the sidekick project as first argument
  final package = SidekickPackage.fromDirectory(Directory(args[0]))!;

  final commandFile = package.root.file('lib/src/${pluginName.snakeCase}.dart');
  commandFile.writeAsStringSync("""
$exampleCommand
""");

  // If your plugin is hosted on pub.dev, use this line
  // pubAddDependency(package, '$pluginName');
  // For local development, use this line instead
  pubAddLocalDependency(package, env['SIDEKICK_LOCAL_PLUGIN_PATH']!);

  pubGet(package);

  registerPlugin(
    sidekickCli: package,
    import: "import 'package:\${package.name}/src/${pluginName.snakeCase}.dart';",
    command: '${pluginName.pascalCase}Command()',
  );
}
''';

  String get exampleCommand => '''
import 'package:sidekick_core/sidekick_core.dart';
import 'package:$pluginName/${pluginName.snakeCase}.dart';

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
    print('\\\$hello from PHNTM!');
    
    final bye = getFarewells().shuffled().first;
    print('\\\$bye from PHNTM!');
  }
}
''';

  String get helpers => '''
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
