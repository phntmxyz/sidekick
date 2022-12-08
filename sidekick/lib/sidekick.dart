import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:sidekick/src/init/init_command.dart';
import 'package:sidekick/src/plugins/plugins_command.dart';
import 'package:sidekick_core/sidekick_core.dart' as skc;
import 'package:sidekick_core/sidekick_core.dart' show Version;

/// The version of package:sidekick
// DO NOT MANUALLY EDIT THIS VERSION, instead run `sk bump-version sidekick`
final Version version = Version.parse('0.7.2');

/// See the [README](https://github.com/phntmxyz/sidekick/blob/main/sidekick/README.md)
/// for more information on sidekick
Future<void> main(List<String> args) async {
  final runner = _SidekickCommandRunner()
    ..addCommand(InitCommand())
    ..addCommand(PluginsCommand());

  try {
    await runner.run(args);
  } on UsageException catch (e) {
    print(e.usage);
    exit(64); // usage error
  }
}

class _SidekickCommandRunner extends CommandRunner {
  _SidekickCommandRunner() : super('sidekick', _desc) {
    argParser.addFlag(
      'version',
      negatable: false,
      help: 'Print version information.',
    );
  }

  @override
  Future<void> run(Iterable<String> args) async {
    final parsedArgs = parse(args);
    if (parsedArgs['version'] == true) {
      print('sidekick: $version\nsidekick_core: ${skc.version}');
      return;
    }
    return super.run(args);
  }

  static const _desc =
      'Generator for a sidekick command line application (cli)';
}
