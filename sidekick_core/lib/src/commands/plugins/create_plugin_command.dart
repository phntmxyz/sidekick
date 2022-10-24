import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/plugins/create_templates/install_only.dart';
import 'package:sidekick_core/src/commands/plugins/create_templates/shared_code.dart';
import 'package:sidekick_core/src/commands/plugins/create_templates/shared_command.dart';
import 'package:sidekick_core/src/commands/plugins/create_templates/template_generator.dart';

/// Generates a new sidekick plugin that can be installed with a sidekick CLI]
///
/// Available templates:
/// - [InstallOnlyTemplate]
/// - [SharedCodeTemplate]
/// - [SharedCommandTemplate]
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
    );

    argParser.addOption(
      'template',
      abbr: 't',
      help: 'Specify the type of plugin to create',
      allowed: templates.keys,
    );
  }

  static const templates = {
    'install-only': InstallOnlyTemplate(),
    'shared-command': SharedCommandTemplate(),
    'shared-code': SharedCodeTemplate(),
  };

  @override
  Future<void> run() async {
    final args = argResults!;

    final name = args['name'] as String?;
    if (name == null) {
      throw UsageException('--name is required', usage);
    }
    if (!isValidPubPackageName(name)) {
      usageException('name: $name is not a valid package name '
          'https://dart.dev/tools/pub/pubspec#name');
    }

    final template = args['template'] as String?;
    if (template == null) {
      throw UsageException('--template is required', usage);
    }

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
      templateType: template,
    );

    final TemplateGenerator generator = templates[template]!;
    generator.generate(templateProperties);
    sidekickDartRuntime.dart(['format', pluginDirectory.path]);
  }
}
