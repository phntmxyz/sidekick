import 'package:args/args.dart';
import 'package:args/command_runner.dart';

/// A [Command] which accepts all arguments and forwards everything to another cli app
///
/// Arguments to format are available via `argResults!.arguments`
abstract class ForwardCommand extends Command {
  ForwardCommand() {
    // recreate the _argParser and change it to allowAnything
    // All args will be handled in the calling script
    _argParser = ArgParser.allowAnything();
  }

  @override
  ArgParser get argParser => _argParser;
  ArgParser _argParser = ArgParser();
}
