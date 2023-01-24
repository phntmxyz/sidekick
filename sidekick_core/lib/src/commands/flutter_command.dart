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
    exitCode = flutter(args, nothrow: true);
  }
}
