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
  final sdk = dartSdk;
  if (sdk == null) {
    throw DartSdkNotSetException();
  }

  final dart = () {
    if (Platform.isWindows) {
      return sdk.file('bin/dart.exe');
    } else {
      return sdk.file('bin/dart');
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
class DartSdkNotSetException implements Exception {}
