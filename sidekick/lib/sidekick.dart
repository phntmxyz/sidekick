import 'package:sidekick/src/init/init_command.dart';
import 'package:sidekick/src/init/sidekick_command_runner.dart';

Future<void> main(List<String> args) async {
  final runner = SidekickCommandRunner()..addCommand(InitCommand());
  await runner.run(args);
}
