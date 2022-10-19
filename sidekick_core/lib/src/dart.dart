import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_core/sidekick_core.dart';

/// Executes the dart cli associated with the project via flutterw
/// https://github.com/passsy/flutter_wrapper
///
/// Makes sure flutterw is executed beforehand to download the dart-sdk
int dart(
  List<String> args, {
  Directory? workingDirectory,
  dcli.Progress? progress,
}) {
  Directory? sdk = dartSdk;
  if (sdk == null) {
    if (flutterSdk != null) {
      final embeddedSdk = flutterSdk!.directory('bin/cache/dart-sdk');
      if (!embeddedSdk.existsSync()) {
        // Flutter SDK is not fully initialized, the Dart SDK not yet downloaded
        // Execute flutter_tool to download the embedded dart runtime
        flutter([], workingDirectory: workingDirectory);
      }
      if (embeddedSdk.existsSync()) {
        sdk = embeddedSdk;
      }
    }
  }
  if (sdk == null) {
    throw DartSdkNotSetException();
  }

  final dart = () {
    if (Platform.isWindows) {
      return sdk!.file('bin/dart.exe');
    } else {
      return sdk!.file('bin/dart');
    }
  }();

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

/// The Dart SDK path is not set in [initializeSidekick] (param [dartSdk])
class DartSdkNotSetException implements Exception {
  @override
  String toString() {
    return "DartSdkNotSetException{message: No Dart SDK set. Please set it in `initializeSidekick(dartSdkPath: 'path/to/sdk')`}.";
  }
}
