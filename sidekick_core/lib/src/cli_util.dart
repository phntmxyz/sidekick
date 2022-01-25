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
  final io.Directory _tempDir =
      tempDir ?? Directory.systemTemp.createTempSync();
  final script = _tempDir.file('${content.md5}.sh')
    ..createSync(recursive: true);
  script.writeAsStringSync(content);
  posix.chmod(script.path, permission: '755');
  return script;
  // TODO add teardown and remove it again
}

/// Executes a script by first writing it as file and then running it as shell script
dcli.Progress writeAndRunShellScript(
  String scriptContent, {
  Directory? workingDirectory,
  dcli.Progress? progress,
}) {
  final script = tempExecutableScriptFile(scriptContent);
  final process = dcli.start(
    script.absolute.path,
    workingDirectory:
        workingDirectory?.absolute.path ?? entryWorkingDirectory.path,
    progress: progress,
  );
  script.deleteSync(recursive: true);
  return process;
}
