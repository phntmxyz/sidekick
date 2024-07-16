import 'dart:async';

import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_core/sidekick_core.dart';

/// Executes Flutter command from Flutter SDK set in [flutterSdk]
///
/// Set [nothrow] to true to ignore errors when executing the flutter command.
/// The exit code will still be non-zero if the command failed and the method
/// will still throw if the Flutter SDK was not set in [initializeSidekick]
///
/// If [throwOnError] is given and the command returns a non-zero exit code,
/// the result of [throwOnError] will be thrown regardless of [nothrow]
Future<ProcessCompletion> flutter(
  List<String> args, {
  Directory? workingDirectory,
  dcli.Progress? progress,
  bool nothrow = false,
  String Function()? throwOnError,
}) async {
  final sdk = flutterSdk;
  if (sdk == null) {
    throw FlutterSdkNotSetException();
  }

  await initializeSdkForPackage(workingDirectory);

  int exitCode = -1;
  try {
    final process = dcli.startFromArgs(
      Platform.isWindows ? 'bash' : sdk.file('bin/flutter').path,
      [if (Platform.isWindows) sdk.file('bin/flutter.exe').path, ...args],
      workingDirectory: workingDirectory?.absolute.path,
      nothrow: nothrow || throwOnError != null,
      progress: progress,
      terminal: progress == null,
    );

    exitCode = process.exitCode ?? -1;
  } catch (e) {
    if (e is dcli.RunException) {
      exitCode = e.exitCode ?? 1;
    }
    if (throwOnError == null) {
      rethrow;
    }
  }
  if (exitCode != 0 && throwOnError != null) {
    throw throwOnError();
  }

  return ProcessCompletion(exitCode: exitCode);
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

/// Returns the Flutter SDK of the `flutter` executable on PATH
Directory? systemFlutterSdk() {
  // /opt/homebrew/bin/flutter
  final path = dcli
          .start('which flutter', progress: Progress.capture(), nothrow: true)
          .lines
          .firstOrNull ??
      env['FLUTTER_ROOT'];
  if (path == null) {
    // flutter not on path or env.FLUTTER_ROOT
    return null;
  }
  final file = File(path);
  // /opt/homebrew/Caskroom/flutter/3.0.4/flutter/bin/flutter
  final realpath = file.resolveSymbolicLinksSync();

  // located in /bin/flutter
  final rootDir = File(realpath).parent.parent;
  return rootDir;
}

/// Returns the path to Flutter SDK of the `flutter` executable on `PATH`
String? systemFlutterSdkPath() => systemFlutterSdk()?.path;
