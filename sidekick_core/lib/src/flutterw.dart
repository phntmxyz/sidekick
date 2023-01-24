import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_core/sidekick_core.dart';

/// Returns the closes `flutterw` file, searching upwards from
/// [SidekickContext.sidekickPackageDir]
File? findFlutterwLocation() {
  final searchStart = SidekickContext.sidekickPackage.root;
  final flutterwParent =
      searchStart.findParent((dir) => dir.file('flutterw').existsSync());
  final flutterw = flutterwParent?.file('flutterw');
  return flutterw;
}

/// Executes Flutter CLI (flutter_tool) via flutter_wrapper
///
/// https://github.com/passsy/flutter_wrapper
///
/// Set [nothrow] to true to ignore errors when executing the flutterw command.
/// The exit code will still be non-zero if the command failed and the method
/// will still throw if no flutterw can be found
@Deprecated('Use flutter() instead')
int flutterw(
  List<String> args, {
  Directory? workingDirectory,
  dcli.Progress? progress,
  bool nothrow = false,
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
      nothrow: nothrow,
      progress: progress,
      terminal: progress == null,
    );
    return process.exitCode ?? -1;
  } else {
    final process = dcli.startFromArgs(
      flutterw.path,
      args,
      workingDirectory: workingDir.path,
      nothrow: nothrow,
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
