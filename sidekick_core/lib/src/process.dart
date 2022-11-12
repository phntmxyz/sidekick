import 'dart:convert';

import 'package:cli_script/cli_script.dart' as cli_script;
import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_core/sidekick_core.dart';

// TODO align API with the process function in flutter_tools
ProcessResult startProcess(
  String executable,
  List<String> args, {
  Directory? workingDirectory,
  dcli.Progress? progress,
}) {
  int? code;

  final result = ProcessResult();

  try {
    result._script = cli_script.Script.capture((stdin) {
      cli_script.run(
        executable,
        args: args,
        workingDirectory: workingDirectory?.path ?? entryWorkingDirectory.path,
      );
    });

    // Consume output streams
    result.script.stdout.listen((line) {
      result._combinedOutput.add(line);
      result._stdoutOutput.add(line);
      if (progress != null) {
        final stringLine = String.fromCharCodes(line);
        for (final trimmed in const LineSplitter().convert(stringLine)) {
          progress.addToStdout(trimmed);
        }
      }
    });
    result.script.stderr.listen((line) {
      result._combinedOutput.add(line);
      result._stderrOutput.add(line);
      if (progress != null) {
        final stringLine = String.fromCharCodes(line);
        for (final trimmed in const LineSplitter().convert(stringLine)) {
          progress.addToStderr(trimmed);
        }
      }
    });

    code = dcli.waitForEx(result.script.exitCode);
    if (code != 0) {
      throw "Dart command failed with exit code $code";
    }
  } catch (e) {
    printerr(result.combinedOutput);
    printerr('');
    if (code != null) {
      printerr("Script failed with exitCode: $code");
    } else {
      printerr("Script execution failed, no exitCode available");
    }
    rethrow;
  }
  result._exitCode = code;
  progress?.exitCode = code;
  progress?.close();

  return result;
}

class ProcessResult {
  cli_script.Script? _script;
  cli_script.Script get script => _script!;

  int? _exitCode;
  int? get exitCode => _exitCode;

  /// combinedOutput will be printed on error. It's important to keep the
  /// order of the lines, mixing stdout and stderr
  final _combinedOutput = BytesBuilder();
  final _stdoutOutput = BytesBuilder();
  final _stderrOutput = BytesBuilder();

  String get combinedOutput => utf8.decode(_combinedOutput.toBytes());
  List<String> get combinedOutputLines =>
      const LineSplitter().convert(combinedOutput);

  String get stdout => utf8.decode(_stdoutOutput.toBytes());
  List<String> get stdoutLines => const LineSplitter().convert(stdout);

  String get stderr => utf8.decode(_stderrOutput.toBytes());
  List<String> get stderrLines => const LineSplitter().convert(stderr);
}
