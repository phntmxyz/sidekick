import 'package:dcli/dcli.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/plugins/create_plugin_command.dart';
import 'package:test/test.dart';

void main() {
  test('check available templates', () {
    final expectedTemplates = [
      'install-only',
      'shared-command',
      'shared-code',
    ];

    expect(CreatePluginCommand.templates.keys, expectedTemplates);
  });

  group('generates valid plugin code', () {
    Future<String> generatePlugin(String template) async {
      final tempDir = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final runner = initializeSidekick(name: 'dash');
      runner.addCommand(CreatePluginCommand());

      await runner.run([
        'create',
        '-t',
        template,
        '-n',
        'generated_plugin',
        tempDir.path,
      ]);
      return tempDir.directory('generated_plugin').path;
    }

    for (final template in CreatePluginCommand.templates.keys) {
      test('for template $template', () async {
        final pluginPath = await generatePlugin(template);

        run('dart pub get', workingDirectory: pluginPath);
        run('dart analyze', workingDirectory: pluginPath);
        run('dart format --set-exit-if-changed $pluginPath');
      });
    }
  });
}
