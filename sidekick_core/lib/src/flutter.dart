import 'dart:async';

import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_core/sidekick_core.dart';

/// Executes Flutter command from Flutter SDK set in [flutterSdk]
int flutter(
  List<String> args, {
  Directory? workingDirectory,
  dcli.Progress? progress,
  bool nothrow = false,
}) {
  final workingDir =
      workingDirectory?.absolute ?? entryWorkingDirectory.absolute;

  final sdk = flutterSdk;
  if (sdk == null) {
    throw FlutterSdkNotSetException();
  }

  for (final initializer in _sdkInitializers) {
    final future = initializer(sdk);
    if (future is Future) {
      dcli.waitForEx(future);
    }
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
      nothrow: nothrow,
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

/// Returns the Flutter SDK of the `flutter` executable on PATH
Directory? systemFlutterSdk() {
  // /opt/homebrew/bin/flutter
  final path = dcli
          .start('which flutter', progress: Progress.capture(), nothrow: true)
          .firstLine ??
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

/// Registers an initializer function that is called before executing the flutter command
/// to prepare the SDK, such as downloading it.
///
/// This is a global function,
Removable addFlutterSdkInitializer(FlutterInitializer initializer) {
  if (!_sdkInitializers.contains(initializer)) {
    _sdkInitializers.add(initializer);
  }
  return () => _sdkInitializers.remove(initializer);
}

/// Can be called to remove a listener
typedef Removable = void Function();

/// Called by [flutter] before executing the flutter executable
typedef FlutterInitializer = FutureOr<void> Function(Directory sdkDir);

/// Initializers that have to be executed before executing the flutter command
List<FlutterInitializer> _sdkInitializers = [];
