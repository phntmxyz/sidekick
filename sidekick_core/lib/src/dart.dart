import 'dart:convert';

import 'package:cli_script/cli_script.dart' as cli_script;
import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_core/sidekick_core.dart';

/// Executes the dart cli associated with the project via flutterw
/// https://github.com/passsy/flutter_wrapper
///
/// Makes sure flutterw is executed beforehand to download the dart-sdk
int dart(
  List<String> args, {
  Directory? workingDirectory,
  @Deprecated('Wrap with Script.capture((){ dart([]); }); instead')
      dcli.Progress? progress,
}) {
  bool flutterwLegacyMode = false;

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
    if (sdk == null) {
      final flutterWrapperLocation = findFlutterwLocation();
      if (flutterWrapperLocation != null) {
        // flutter_wrapper is installed, going into legacy mode for those which have not set the flutterSdkPath
        final embeddedSdk =
            repository.root.directory('.flutter/bin/cache/dart-sdk');
        if (!embeddedSdk.existsSync()) {
          // Flutter SDK is not fully initialized, the Dart SDK not yet downloaded
          // Execute flutter_tool to download the embedded dart runtime
          // ignore: deprecated_member_use_from_same_package
          flutterw([], workingDirectory: workingDirectory);
        }
        if (embeddedSdk.existsSync()) {
          sdk = embeddedSdk;
          flutterwLegacyMode = true;
        }
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

  /// combinedOutput will be printed on error. It's important to keep the
  /// order of the lines, mixing stdout and stderr
  final combinedOutput = StringBuffer();
  cli_script.Script? script;
  int? code;
  try {
    script = cli_script.Script.capture((stdin) {
      cli_script.run(
        dart.path,
        args: args,
        workingDirectory: workingDirectory?.path ?? entryWorkingDirectory.path,
      );
    });

    // Consume output streams
    script.stdout.listen((line) {
      final stringLine = String.fromCharCodes(line);
      combinedOutput.write(stringLine);
      if (progress != null) {
        for (final trimmed in const LineSplitter().convert(stringLine)) {
          progress.addToStdout(trimmed);
        }
      }
    });
    script.stderr.listen((line) {
      final stringLine = String.fromCharCodes(line);
      combinedOutput.write(stringLine);
      if (progress != null) {
        for (final trimmed in const LineSplitter().convert(stringLine)) {
          progress.addToStderr(trimmed);
        }
      }
    });

    code = dcli.waitForEx(script.exitCode);
    if (code != 0) {
      throw "Dart command failed with exit code $code";
    }
  } catch (e) {
    printerr(combinedOutput.toString());
    printerr('');
    if (code != null) {
      printerr("Script failed with exitCode: $code");
    } else {
      printerr("Script execution failed, no exitCode available");
    }
    rethrow;
  }

  if (flutterwLegacyMode) {
    printerr("Sidekick Warning: ${DartSdkNotSetException().message}");
  }
  progress?.exitCode = code;
  progress?.close();
  return code ?? -1;
}

/// The Dart SDK path is not set in [initializeSidekick] (param [dartSdk], neither is is the [flutterSdk])
class DartSdkNotSetException implements Exception {
  final String message =
      "No Dart SDK set. Please set it in `initializeSidekick(dartSdkPath: 'path/to/sdk')`";

  @override
  String toString() {
    return "DartSdkNotSetException{message: $message}";
  }
}

/// Executes the system dart cli which is globally available on PATH
int systemDart(
  List<String> args, {
  Directory? workingDirectory,
  dcli.Progress? progress,
}) {
  final systemDartExecutablePath = systemDartExecutable();
  if (systemDartExecutablePath == null) {
    throw "Couldn't find dart executable on PATH.";
  }

  final process = dcli.startFromArgs(
    systemDartExecutablePath,
    args,
    workingDirectory: workingDirectory?.path ?? entryWorkingDirectory.path,
    progress: progress,
    terminal: progress == null,
  );

  return process.exitCode ?? -1;
}

String? systemDartExecutable() =>
    // /opt/homebrew/bin/dart
    dcli
        .start('which dart', progress: Progress.capture(), nothrow: true)
        .firstLine;

/// Returns the Dart SDK of the `dart` executable on `PATH`
Directory? systemDartSdk() {
  // /opt/homebrew/bin/dart
  final path = systemDartExecutable();
  if (path == null) {
    // dart not on path
    return null;
  }
  final file = File(path);
  // /opt/homebrew/Cellar/dart/2.18.1/libexec/bin/dart
  final realpath = file.resolveSymbolicLinksSync();

  final libexec = File(realpath).parent.parent;
  return libexec;
}

/// Returns the path to Dart SDK of the `dart` executable on `PATH`
String? systemDartSdkPath() => systemDartSdk()?.path;
