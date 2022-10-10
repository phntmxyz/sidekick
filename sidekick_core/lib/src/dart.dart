import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_core/sidekick_core.dart';

/// Executes the dart cli associated with the project via flutterw
///
/// Makes sure flutterw is executed beforehand to download the dart-sdk
int dart(
  List<String> args, {
  Directory? workingDirectory,
  dcli.Progress? progress,
}) {
  final binDir = repository.root.directory('.flutter/bin/cache/dart-sdk/bin/');
  final dart = () {
    if (Platform.isWindows) {
      return binDir.file('dart.exe');
    } else {
      return binDir.file('dart');
    }
  }();

  if (!dart.existsSync()) {
    // run a flutterw command forcing flutter_tool to download the dart sdk
    print("running flutterw to download dart");
    flutterw([], workingDirectory: mainProject!.root);
  }
  final process = dcli.startFromArgs(
    dart.path,
    args,
    workingDirectory: workingDirectory?.path ?? entryWorkingDirectory.path,
    progress: progress,
    nothrow: true,
    terminal: progress == null,
  );
  return process.exitCode ?? -1;
}
