import 'package:sidekick_core/sidekick_core.dart';

/// Makes the `flutter` command available as subcommand
///
/// Links to the embedded flutter, not flutter installed on the system
class FlutterCommand extends ForwardCommand {
  @override
  final String description =
      'Use the Flutter SDK associated with the project (Calls flutterw).\n'
      'Can be used inside packages instead of calling ./../../flutterw';

  @override
  final String name = 'flutter';

  @override
  Future<void> run() async {
    // TODO find pinned fvm flutter version
    try {
      final exitCode = flutterw(argResults!.arguments);
      exit(exitCode);
    } on FlutterWrapperNotFoundException catch (_) {
      printerr(
        'Could not find a pinned flutter version associated with the project.\n'
        'Please install https://github.com/passsy/flutter_wrapper, to pin a flutter version',
      );
    }
  }
}
