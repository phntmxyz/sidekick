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
        final embeddedSdk = SidekickContext.repository.root
            .directory('.flutter/bin/cache/dart-sdk');
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

  final process = dcli.startFromArgs(
    dart.path,
    args,
    workingDirectory: workingDirectory?.path ?? entryWorkingDirectory.path,
    progress: progress,
    nothrow: true,
    terminal: progress == null,
  );

  if (flutterwLegacyMode) {
    printerr("Sidekick Warning: ${DartSdkNotSetException().message}");
  }
  return process.exitCode ?? -1;
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
