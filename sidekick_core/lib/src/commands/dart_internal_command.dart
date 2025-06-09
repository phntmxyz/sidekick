import 'package:sidekick_core/sidekick_core.dart';

/// Executes the embedded Dart SDK managed by sidekick
///
/// This command provides direct access to the Dart runtime that sidekick
/// downloads and manages, allowing execution of Dart commands using the
/// same SDK version as the CLI.
///
/// Usage examples:
///   `<cli> sidekick dart-internal --version`
///   `<cli> sidekick dart-internal pub get`
///   `<cli> sidekick dart-internal run main.dart`
///
/// Note: This command is intercepted by the bash script and never actually
/// executed by the Dart CLI. It exists only for documentation in help output.
class DartInternalCommand extends Command {
  @override
  final String description =
      'Executes the embedded Dart SDK managed by sidekick (useful for recovery when CLI compilation fails)';

  @override
  final String name = 'dart-internal';

  @override
  Future<void> run() {
    throw StateError(
      'This command should never be executed. '
      'It is intercepted by the bash script.',
    );
  }
}
