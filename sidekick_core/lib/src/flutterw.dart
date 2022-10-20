import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_core/sidekick_core.dart';

/// Returns the closes `flutterw` file, searching upwards from [mainProject] or [Repository.cliPackageDir] or [repository]
File? findFlutterwLocation() {
  final searchStart =
      mainProject?.root ?? Repository.cliPackageDir ?? repository.root;
  final flutterwParent =
      searchStart.findParent((dir) => dir.file('flutterw').existsSync());
  final flutterw = flutterwParent?.file('flutterw');
  return flutterw;
}

/// Executes Flutter CLI (flutter_tool) via flutter_wrapper
///
/// https://github.com/passsy/flutter_wrapper
@Deprecated('Use flutter() instead')
int flutterw(
  List<String> args, {
  Directory? workingDirectory,
  dcli.Progress? progress,
}) {
  final flutterw = findFlutterwLocation();
  if (flutterw == null) {
    throw FlutterWrapperNotFoundException();
  }
  final workingDir =
      workingDirectory?.absolute ?? entryWorkingDirectory.absolute;

  if (Platform.isWindows) {
    final process = dcli.startFromArgs(
      'bash',
      [flutterw.path, ...args],
      workingDirectory: workingDir.path,
      nothrow: true,
      progress: progress,
      terminal: progress == null,
    );
    return process.exitCode ?? -1;
  } else {
    final process = dcli.startFromArgs(
      flutterw.path,
      args,
      workingDirectory: workingDir.path,
      nothrow: true,
      progress: progress,
      terminal: progress == null,
    );
    return process.exitCode ?? -1;
  }
}

/// Thrown when flutterw is not found
///
/// https://github.com/passsy/flutter_wrapper
class FlutterWrapperNotFoundException implements Exception {}
