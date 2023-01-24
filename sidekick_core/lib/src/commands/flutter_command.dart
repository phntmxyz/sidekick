import 'package:sidekick_core/sidekick_core.dart';

/// Makes the `flutter` command available as subcommand
///
/// Links to the embedded flutter, not flutter installed on the system
class FlutterCommand extends ForwardCommand {
  @override
  final String description = 'Call the Flutter SDK associated with the project';

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
        // ignore: deprecated_member_use_from_same_package
        exitCode = flutterw(args, nothrow: true);
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
