import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_core/sidekick_core.dart';

/// Executes a git command
int git(
  List<String> args, {
  Directory? workingDirectory,
  dcli.Progress? progress,
}) {
  final workingDir =
      workingDirectory?.absolute.path ?? entryWorkingDirectory.absolute.path;
  final process = dcli.startFromArgs(
    'git',
    args,
    workingDirectory: workingDir,
    nothrow: true,
    progress: progress,
    terminal: progress == null,
  );
  return process.exitCode ?? -1;
}
