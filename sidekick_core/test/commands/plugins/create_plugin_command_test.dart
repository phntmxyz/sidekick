import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/plugins/create_plugin_command.dart';
import 'package:test/test.dart';
import 'package:dcli/dcli.dart';

void main() {
  group('generates valid plugin code', () {
    const templates = ['install-only', 'shared-command', 'shared-code'];

    Future<String> generatePlugin(String template) async {
      final tempDir = Directory.systemTemp.createTempSync();
      //addTearDown(() => tempDir.deleteSync(recursive: true));

      final runner = initializeSidekick(name: 'dash');
      runner.addCommand(CreatePluginCommand());

      await runner.run(
          ['create', '-t', template, '-n', 'generated_plugin', tempDir.path]);
      return tempDir.directory('generated_plugin').path;
    }

    for (final template in templates) {
      test('for template $template', () async {
        final pluginPath = await generatePlugin(template);

        run('dart pub get', workingDirectory: pluginPath);
        run('dart analyze', workingDirectory: pluginPath);
        
        run('git init', workingDirectory: pluginPath);
        run('git add .', workingDirectory: pluginPath);
        run('git commit -am "initial"', workingDirectory: pluginPath);

        run('dart format --set-exit-if-changed $pluginPath');
      });
    }
  });
}
