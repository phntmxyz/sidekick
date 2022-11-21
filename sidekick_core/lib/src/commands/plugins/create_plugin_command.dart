import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/plugins/create_templates/install_only.dart';
import 'package:sidekick_core/src/commands/plugins/create_templates/plugin_template_generator.dart';
import 'package:sidekick_core/src/commands/plugins/create_templates/shared_code.dart';
import 'package:sidekick_core/src/commands/plugins/create_templates/shared_command.dart';

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
      help: 'The plugin name (should end with _sidekick_plugin)',
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

    final templateProperties = PluginTemplateProperties(
      pluginName: name,
      pluginDirectory: pluginDirectory,
      templateType: template,
    );

    final PluginTemplateGenerator generator = templates[template]!;
    generator.generate(templateProperties);

    final formatArgs = ['format', pluginDirectory.path];

    // TODO find a better workaround than this hack
    final usingGlobalSidekickCli = () {
      try {
        // when running from global sidekick CLI, accessing `dartSdk` throws 'You cannot access dartSdk outside of a Command executed with SidekickCommandRunner.'
        if (dartSdk != null) {
          return false;
        }
      } catch (_) {
        // ignore
      }
      return true;
    }();

    if (usingGlobalSidekickCli) {
      // command is run from global sidekick CLI
      systemDart(formatArgs);
    } else {
      // command is run from generated sidekick CLI which has its own Dart SDK
      sidekickDartRuntime.dart(formatArgs);
    }
  }
}
