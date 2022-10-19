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
}
