import 'package:args/command_runner.dart';

class SidekickCommandRunner extends CommandRunner {
  SidekickCommandRunner() : super('sidekick', _desc);

  static const _desc =
      'Generator for a sidekick command line application (cli)';
}
