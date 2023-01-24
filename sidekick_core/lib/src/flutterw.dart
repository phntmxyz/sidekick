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
///
/// If [throwOnError] is given and the command returns a non-zero exit code,
/// the result of [throwOnError] will be thrown regardless of [nothrow]
@Deprecated('Use flutter() instead')
int flutterw(
  List<String> args, {
  Directory? workingDirectory,
  dcli.Progress? progress,
  bool nothrow = false,
  String Function(int code)? throwOnError,
}) {
  final flutterw = findFlutterwLocation();
  if (flutterw == null) {
    throw FlutterWrapperNotFoundException();
  }
  final workingDir =
      workingDirectory?.absolute ?? entryWorkingDirectory.absolute;

  final process = dcli.startFromArgs(
    Platform.isWindows ? 'bash' : flutterw.path,
    [if (Platform.isWindows) flutterw.path, ...args],
    workingDirectory: workingDir.path,
    nothrow: nothrow || throwOnError != null,
    progress: progress,
    terminal: progress == null,
  );

  final exitCode = process.exitCode ?? -1;

  if (exitCode != 0 && throwOnError != null) {
    throw throwOnError(exitCode);
  }

  return exitCode;
}

/// Thrown when flutterw is not found
///
/// https://github.com/passsy/flutter_wrapper
class FlutterWrapperNotFoundException implements Exception {}
