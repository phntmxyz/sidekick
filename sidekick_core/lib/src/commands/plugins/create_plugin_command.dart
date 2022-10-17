import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:recase/recase.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/plugins/create_templates/generation_properties.dart';

import 'package:sidekick_core/src/commands/plugins/create_templates/shared_code.dart'
    as sharedCode;
import 'package:sidekick_core/src/commands/plugins/create_templates/shared_command.dart'
    as sharedCommand;
import 'package:sidekick_core/src/commands/plugins/create_templates/install_only.dart'
    as installOnly;

class CreatePluginCommand extends Command {
  @override
  final String description = 'Create a new sidekick plugin from a template';

  @override
  final String name = 'create';

  CreatePluginCommand() {
    argParser.addOption(
      'name',
      abbr: 'n',
      help: 'The plugin name',
      mandatory: true,
    );

    argParser.addOption(
      'template',
      abbr: 't',
      help: 'Specify the type of plugin to create',
      allowed: [
        // only has a tool/install.dart file
        'install-only',

        // the whole command is shared in the package
        // sidekick users are not able to change code, only input parameters
        'shared-command',

        // some shared code, but the command itself is copied into the
        // user's sidekick CLI. This makes it easy to modify
        'shared-code',
      ],
      mandatory: true,
    );
  }

  @override
  Future<void> run() async {
    final args = argResults!;

    final name = args['name'] as String;

    // TODO if(!isValidCliName(name)){usageException...}

    // TODO validate: name must be valid dart package name

    final template = args['template'] as String;

    final path = args.rest.firstOrNull ?? Directory.current.path;

    final pluginDirectory = Directory(path).directory(name);

    if (pluginDirectory.existsSync()) {
      usageException("Tried to generate plugin '$name', "
          "but directory ${pluginDirectory.path} already exists. "
          "Try choosing another plugin name.");
    }

    pluginDirectory.createSync(recursive: true);

    final templateProperties = TemplateProperties(
      pluginName: name,
      pluginDirectory: pluginDirectory,
    );

    switch (template) {
      case 'install-only':
        installOnly.generate(templateProperties);
        break;
      case 'shared-command':
        sharedCommand.generate(templateProperties);
        break;
      case 'shared-code':
        sharedCode.generate(templateProperties);
        break;
      default:
        throw StateError('unreachable');
    }
  }
}
