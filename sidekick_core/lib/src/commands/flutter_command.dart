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
    final args = argResults!.arguments;
    try {
      exitCode = flutter(args);
    } on FlutterSdkNotSetException catch (original) {
      // for backwards compatibility link to the previous required flutter_wrapper location
      try {
        exitCode = flutterw(args);
        printerr("Sidekick Warning: ${original.message}");
        // success with flutterw, immediately return
        return;
      } on FlutterWrapperNotFoundException catch (_) {
        // rethrow original below
      }
      rethrow /* original */;
    }
  }
}
