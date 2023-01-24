import 'dart:async';

import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_core/sidekick_core.dart';

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
            workingDirectory?.absolute.path,
        progress: progress,
        terminal: withStdIn,
      );
    } catch (e, stack) {
      throw BashCommandException(
        script: bashScript,
        commandName: name,
        arguments: argResults!.arguments,
        exitCode: progress.exitCode!,
        cause: e,
        stack: stack,
      );
    } finally {
      scriptFile.deleteSync(recursive: true);
    }
  }
}

/// Exception thrown when a [BashCommand] fails containing all the information
/// about the script and its error
class BashCommandException implements Exception {
  /// The actual script content that was executed
  final String script;

  /// The name of the command that executed this script
  final String commandName;

  /// The arguments passed into the command
  final List<String> arguments;

  /// The exit code of the script that caused the error. (Always != `0`)
  final int exitCode;

  /// The complete stacktrace, going into dcli which was ultimately executing this script
  final StackTrace stack;

  /// The original exception from dcli
  final Object cause;

  const BashCommandException({
    required this.script,
    required this.commandName,
    required this.arguments,
    required this.exitCode,
    required this.stack,
    required this.cause,
  });

  @override
  String toString() {
    String args = arguments.joinToString(separator: ' ');
    if (!args.isBlank) {
      args = "($args)";
    } else {
      args = '<no arguments>';
    }
    return "Error (exitCode=$exitCode) executing script of command '$commandName' "
        "with arguments: $args\n\n"
        "'''bash\n"
        "${script.trimRight()}\n"
        "'''\n\n";
  }
}
