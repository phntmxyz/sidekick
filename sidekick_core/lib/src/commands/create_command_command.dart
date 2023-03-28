import 'package:recase/recase.dart';
import 'package:sidekick_core/sidekick_core.dart';

/// Adds a new command to the current sidekick CLI
class CreateCommandCommand extends Command {
  @override
  final String description = 'Creates a new command';

  @override
  final String name = 'create-command';

  @override
  String get invocation =>
      super.invocation.replaceFirst('[arguments]', '[name]');

  CreateCommandCommand() {
    argParser.addOption(
      'description',
      abbr: 'd',
      help: 'Description of the command',
    );
  }

  @override
  Future<void> run() async {
    final String commandName = singleRestArgOrThrow(argResults!, 'name');
    final String? description = argResults!['description'] as String?;

    final commandsDir =
        SidekickContext.sidekickPackage.root.directory('lib/src/commands');
    final commandFile =
        commandsDir.file('${commandName.snakeCase}_command.dart');

    if (commandFile.existsSync()) {
      print('Command $commandName already exists at ${commandFile.path}');
      exitCode = 1;
      return;
    }

    commandFile.parent.createSync(recursive: true);
    commandFile.writeAsStringSync('''
import 'package:sidekick_core/sidekick_core.dart';

class ${commandName.pascalCase}Command extends Command {
  @override
  final String description = '${description ?? 'TODO: Add description'}';

  @override
  final String name = '${commandName.paramCase}';
  
  ${commandName.pascalCase}Command() {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: '', // TODO add help
    );
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: '', // TODO add help
    );
  }
  
  @override
  Future<void> run() async {
    final String? nameArg = argResults!['name'] as String?;
    final bool force = argResults!['force'] as bool;
    final String? path = argResults!.rest.firstOrNull;
    
    final apiPackage = SidekickContext.projectRoot
     .directory('packages/${SidekickContext.cliName}_api');
    
    print(green('\$name finished successfully 🎉'));
    // TODO implement your logic
  }
}
''');

    // register command
    final commandRegisteringFile = SidekickContext.sidekickPackage.libDir
        .file('${SidekickContext.cliName}_sidekick.dart');
    // add import
    _addImport(
      commandRegisteringFile,
      "import 'package:${SidekickContext.sidekickPackage.name}/src/commands/${commandName.snakeCase}_command.dart';",
    );

    // add command
    commandRegisteringFile.replaceFirst(
      '..addCommand(SidekickCommand())',
      '..addCommand(SidekickCommand())'
          '\n    '
          '..addCommand(${commandName.pascalCase}Command())',
    );
  }

  String singleRestArgOrThrow(ArgResults argResults, String name) {
    if (argResults.rest.isEmpty) {
      throw UsageException('Missing argument $name', usage);
    }
    if (argResults.rest.length > 1) {
      throw UsageException('Too many arguments', usage);
    }
    return argResults.rest.first;
  }
}

/// Simplistic way to add a import to a dart file.
///
/// It uses regex instead of the analyzer to avoid adding a dependency to the
/// analyzer package. If it doesn't work, copy the `addImport()` function from
/// package:sidekick_plugin_installer
void _addImport(File file, String import) {
  if (!file.existsSync()) {
    throw Exception('File ${file.path} does not exist');
  }
  if (!file.name.endsWith('.dart')) {
    throw Exception('File ${file.path} is not a dart file');
  }

  final content = file.readAsStringSync();
  final lastImport =
      content.lastIndexOf(RegExp('^import .*;\n', multiLine: true));
  final firstSemicolonAfterImport =
      lastImport == -1 ? -1 : content.indexOf(';', lastImport);

  String updated;
  if (lastImport == -1) {
    updated = "$import\n\n$content";
  } else {
    updated = content.replaceRange(
      firstSemicolonAfterImport + 1,
      firstSemicolonAfterImport + 1,
      '\n$import',
    );
  }
  file.writeAsStringSync(updated);
}
