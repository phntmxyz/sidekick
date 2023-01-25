import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:sidekick/src/commands/init_command.dart';
import 'package:sidekick/src/commands/plugins_command.dart';
import 'package:sidekick/src/commands/update_command.dart';
import 'package:sidekick_core/sidekick_core.dart' as core;
import 'package:sidekick_core/sidekick_core.dart' show Version;

/// The version of package:sidekick
// DO NOT MANUALLY EDIT THIS VERSION, instead run `sk bump-version sidekick`
final Version version = Version.parse('0.10.0');

/// See the [README](https://github.com/phntmxyz/sidekick/blob/main/sidekick/README.md)
/// for more information on sidekick
Future<void> main(List<String> args) async {
  final runner = GlobalSidekickCommandRunner();

  try {
    await runner.run(args);
  } on UsageException catch (e) {
    print(e);
    exit(64); // usage error
  }
}

@visibleForTesting
class GlobalSidekickCommandRunner extends CommandRunner {
  GlobalSidekickCommandRunner({
    this.processManager = const LocalProcessManager(),
  }) : super('sidekick', _desc) {
    argParser.addFlag(
      'version',
      negatable: false,
      help: 'Print version information.',
    );

    addCommand(InitCommand());
    addCommand(
      UpdateCommand(processManager: processManager),
    );
    addCommand(PluginsCommand());
  }

  final ProcessManager processManager;

  @override
  Future<void> run(Iterable<String> args) async {
    final parsedArgs = parse(args);
    if (parsedArgs['version'] == true) {
      print('sidekick: $version\nsidekick_core: ${core.version}');
      return;
    }
    return super.run(args);
  }

  static const _desc =
      'Generator for a sidekick command line application (cli)';
}
