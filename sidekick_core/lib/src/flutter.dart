import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_core/sidekick_core.dart';

/// Executes Flutter command from Flutter SDK set in [flutterSdk]
int flutter(
  List<String> args, {
  Directory? workingDirectory,
  dcli.Progress? progress,
}) {
  final workingDir =
      workingDirectory?.absolute ?? entryWorkingDirectory.absolute;

  final sdk = flutterSdk;
  if (sdk == null) {
    throw FlutterSdkNotSetException();
  }

  if (Platform.isWindows) {
    final process = dcli.startFromArgs(
      'bash',
      [sdk.file('bin/flutter.exe').path, ...args],
      workingDirectory: workingDir.path,
      nothrow: true,
      progress: progress,
      terminal: progress == null,
    );
    return process.exitCode ?? -1;
  } else {
    final process = dcli.startFromArgs(
      sdk.file('bin/flutter').path,
      args,
      workingDirectory: workingDir.path,
      nothrow: true,
      progress: progress,
      terminal: progress == null,
    );
    return process.exitCode ?? -1;
  }
}

/// The Flutter SDK path is not set in [initializeSidekick] (param [flutterSdk])
class FlutterSdkNotSetException implements Exception {
  final String message =
      "No Flutter SDK set. Please set it in `initializeSidekick(flutterSdkPath: 'path/to/sdk')`";
  @override
  String toString() {
    return "FlutterSdkNotSetException{message: $message}";
  }
}
