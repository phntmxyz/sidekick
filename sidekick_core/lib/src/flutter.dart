import 'dart:async';

import 'package:dcli/dcli.dart' as dcli;
import 'package:exec/exec.dart';
import 'package:sidekick_core/sidekick_core.dart';

/// Executes Flutter command from Flutter SDK set in [flutterSdk]
///
/// Set [nothrow] to true to ignore errors when executing the flutter command.
/// The exit code will still be non-zero if the command failed and the method
/// will still throw if the Flutter SDK was not set in [initializeSidekick]
///
/// If [throwOnError] is given and the command returns a non-zero exit code,
/// the result of [throwOnError] will be thrown regardless of [nothrow]
Future<ExecResult> flutter(
  List<String> args, {
  Directory? workingDirectory,
  bool nothrow = false,
  String Function()? throwOnError,
  ExecOutput output = ExecOutput.mirror,
}) async {
  final sdk = flutterSdk;
  if (sdk == null) {
    throw FlutterSdkNotSetException();
  }

  await initializeSdkForPackage(workingDirectory);

  ExecResult? result;
  try {
    result = await Exec.run(
      Platform.isWindows ? 'bash' : sdk.file('bin/flutter').path,
      [if (Platform.isWindows) sdk.file('bin/flutter.exe').path, ...args],
      workingDirectory: workingDirectory?.absolute.path,
      check: !(nothrow || throwOnError != null),
      output: output,
      environment: envs,
      includeParentEnvironment: false,
    );
  } catch (e) {
    // A failed run keeps its diagnostics; a failed launch has none.
    if (e is ExecException) {
      result = e.execution;
    }
    if (throwOnError == null) {
      rethrow;
    }
  }
  if (result == null || result.exitCode != 0) {
    if (throwOnError != null) {
      throw throwOnError();
    }
  }

  return result!;
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
