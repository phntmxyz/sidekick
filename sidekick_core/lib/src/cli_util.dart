import 'dart:io' as io;

import 'package:dcli/dcli.dart' as dcli;
import 'package:dcli/posix.dart' as posix;
import 'package:sidekick_core/sidekick_core.dart';

/// Exits the CLI immediately with a messages
Never error(String message, {int? errorCode}) {
  assert(
    () {
      throw message;
    }(),
  );
  io.stderr.writeln(message);

  final code = errorCode ?? -1;
  exitCode = code;
  io.exit(code);
}

/// Returns true when the cli program named [name] is available via PATH
bool isProgramInstalled(String name) {
  return dcli.which(name).found;
}

/// Writes [content] as executable *.sh file in a temp directory
///
/// The file name is the md5 hash of the content, therefore doesn't create a new file when called with the same content
io.File tempExecutableScriptFile(String content, {Directory? tempDir}) {
  final io.Directory dir = tempDir ?? Directory.systemTemp.createTempSync();
  final script = dir.file('${content.md5}.sh')..createSync(recursive: true);
  script.writeAsStringSync(content);
  posix.chmod(script.path, permission: '755');
  return script;
}

/// Executes a script by first writing it as file and then running it as shell script
///
/// Use [args] to pass arguments to the script
///
/// Use [workingDirectory] to set the working directory of the script, default
/// to current working directory
///
/// When [terminal] is `true` (default: `false`) Stdio handles are inherited by
/// the child process. This allows stdin to read by the script
dcli.Progress writeAndRunShellScript(
  String scriptContent, {
  List<String> args = const [],
  Directory? workingDirectory,
  dcli.Progress? progress,
  bool terminal = false,
}) {
  final script = tempExecutableScriptFile(scriptContent);
  final Progress scriptProgress =
      progress ?? Progress(print, stderr: printerr, captureStderr: true);

  try {
    return dcli.startFromArgs(
      script.absolute.path,
      args,
      workingDirectory: workingDirectory?.absolute.path,
      progress: scriptProgress,
      terminal: terminal,
    );
  } catch (e) {
    print(
      "\nError executing script:\n\n"
      "$scriptContent",
    );
    if (progress == null) {
      print(
        "The captured error of running the script is:\n"
        "${scriptProgress.toList().join('\n')}\n",
      );
    }
    rethrow;
  } finally {
    script.deleteSync(recursive: true);
  }
}
