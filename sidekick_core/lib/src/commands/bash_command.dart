import 'dart:async';

import 'package:sidekick_core/sidekick_core.dart';
import 'package:dcli/dcli.dart' as dcli;

/// A Command that wraps a bash script
///
/// Easy way to convert an existing bash script into a command for sidekick
///
/// This makes it easy to handle paths within the bash script. You can define a
/// static [workingDirectory] and always know where the script is executed.
///
/// Usage as plain text
/// ```dart
/// runner
///   ..addCommand(
///      BashCommand(
///        name: 'test-bash-command',
///        description: 'Prints inputs of a sidekick BashCommand',
///        workingDirectory: runner.repository.root,
///        script: () => '''
/// echo "arguments: \$@"
/// echo "workingDirectory: \$(pwd)"
/// # Access paths from sidekick
/// ${systemFlutterSdkPath()}/bin/flutter --version
/// ''',
///     ),
///   );
/// ```
///
/// Or load your script from a file
/// ```dart
/// runner
///   ..addCommand(
///     BashCommand(
///       name: 'test-bash-command',
///       description: 'Prints inputs of a sidekick BashCommand',
///       workingDirectory: runner.repository.root,
///       script: () => runner.repository.root
///           .file('scripts/test-bash-command.sh')
///           .readAsString(),
///     ),
///   )
/// ```
///
/// If your script is interactive, set [withStdIn] to `true` to allow stdin to
/// be connected to the script.
class BashCommand extends ForwardCommand {
  BashCommand({
    required this.script,
    required this.description,
    required this.name,
    this.workingDirectory,
    this.withStdIn = false,
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

  /// Whether to forward stdin to the bash script, default to true
  final bool withStdIn;

  @override
  Future<void> run() async {
    final bashScript = await script();

    final scriptFile = tempExecutableScriptFile(bashScript);
    final Progress progress =
        Progress(print, stderr: printerr, captureStderr: true);

    try {
      dcli.startFromArgs(
        scriptFile.absolute.path,
        argResults!.arguments,
        workingDirectory:
            workingDirectory?.absolute.path ?? entryWorkingDirectory.path,
        progress: progress,
        terminal: withStdIn,
      );
    } catch (e) {
      printerr(
        "\nError executing script '$name' (exitCode=${progress.exitCode}):\n"
        "$bashScript\n\n"
        "Error executing script '$name' (exitCode=${progress.exitCode})",
      );
      rethrow;
    } finally {
      scriptFile.deleteSync(recursive: true);
    }
  }
}
