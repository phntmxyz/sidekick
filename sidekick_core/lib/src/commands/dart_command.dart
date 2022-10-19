import 'package:sidekick_core/sidekick_core.dart';

/// Makes the `dart` command available as subcommand
///
/// Uses the embedded dart sdk in the flutter sdk, not dart installed on the system
class DartCommand extends ForwardCommand {
  @override
  final String description = 'Calls dart';

  @override
  final String name = 'dart';

  @override
  Future<void> run() async {
    exitCode = dart(argResults!.arguments);
  }
}
