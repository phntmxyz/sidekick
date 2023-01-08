import 'dart:async';

import 'package:sidekick_core/sidekick_core.dart';

/// A Command that wraps a bash script
///
/// Easy way to convert an existing bash script into a command for sidekick
///
/// This makes it easy to handle paths within the bash script. You can define a
/// static [workingDirectory] and always know where the script is executed.
///
/// Usage:
/// ```dart
/// runner
///    ..addCommand(
///       BashCommand(
///         name: 'test-bash-command',
///         description: 'Prints inputs of a sidekick BashCommand',
///         workingDirectory: runner.repository.root,
///         script: () => '''
/// echo "arguments: \$@"
/// echo "workingDirectory: \$(pwd)"
/// # Access paths from sidekick
/// ${systemFlutterSdkPath()}/bin/flutter --version
///       ''',
///       );
/// ```
class BashCommand extends ForwardCommand {
  BashCommand({
    required this.script,
    required this.description,
    required this.name,
    this.workingDirectory,
  });

  @override
  final String name;

  @override
  final String description;

  /// The script to be executed.
  ///
  /// You may load this script from a file or generate it on the fly.
  final FutureOr<String> Function() script;

  /// The directory the bash script is running in.
  final Directory? workingDirectory;

  @override
  Future<void> run() async {
    final bashScript = await script();
    writeAndRunShellScript(
      bashScript,
      args: argResults!.arguments,
      workingDirectory: workingDirectory,
      terminal: true,
    );
  }
}
