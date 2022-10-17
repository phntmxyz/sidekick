import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:sidekick/src/init/init_command.dart';
import 'package:sidekick/src/plugins/plugins_command.dart';

Future<void> main(List<String> args) async {
  final runner = _SidekickCommandRunner()
    ..addCommand(InitCommand())
    ..addCommand(PluginsCommand());
}

class _SidekickCommandRunner extends CommandRunner {
  _SidekickCommandRunner() : super('sidekick', _desc);

  static const _desc =
      'Generator for a sidekick command line application (cli)';
}
