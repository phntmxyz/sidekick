import 'package:dcli/dcli.dart' as dcli;
import 'package:exec/exec.dart';
import 'package:sidekick_core/sidekick_core.dart';

/// Executes the dart cli associated with the project via flutterw
/// https://github.com/passsy/flutter_wrapper
///
/// Makes sure flutterw is executed beforehand to download the dart-sdk
///
/// Set [nothrow] to true to ignore errors when executing the dart command.
/// The exit code will still be non-zero if the command failed and the method
/// will still throw if the Dart SDK was not set in [initializeSidekick]
///
/// If [throwOnError] is given and the command returns a non-zero exit code,
/// the result of [throwOnError] will be thrown regardless of [nothrow]
Future<ExecResult> dart(
  List<String> args, {
  Directory? workingDirectory,
  bool nothrow = false,
  String Function()? throwOnError,
  ExecOutput output = ExecOutput.mirror,
}) async {
  Directory? sdk = dartSdk;
  if (sdk == null && flutterSdk != null) {
    final embeddedSdk = flutterSdk!.directory('bin/cache/dart-sdk');
    if (!embeddedSdk.existsSync()) {
      // Flutter SDK is not fully initialized, the Dart SDK not yet downloaded
      // Execute flutter_tool to download the embedded dart runtime
      await flutter([], workingDirectory: workingDirectory, nothrow: true);
    }
    if (embeddedSdk.existsSync()) {
      sdk = embeddedSdk;
    }
  }
  if (sdk == null) {
    throw DartSdkNotSetException();
  }

  await initializeSdkForPackage(workingDirectory);

  final dart =
      Platform.isWindows ? sdk.file('bin/dart.exe') : sdk.file('bin/dart');

  final result = await Exec.run(
    dart.path,
    args,
    workingDirectory: workingDirectory?.path,
    output: output,
    check: !(nothrow || throwOnError != null),
    // exec hands over its complete environment map, so this does not shrink
    // what the child receives. It stops the parent process from reinstating
    // variables that were removed from the scoped environment, which is the
    // only way `env['FOO'] = null` can reach a child process.
    environment: envs,
    includeParentEnvironment: false,
  );

  if (result.exitCode != 0 && throwOnError != null) {
    throw throwOnError();
  }

  return result;
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
///
/// Set [nothrow] to true to ignore errors when executing the dart command.
/// The exit code will still be non-zero if the command failed and the method
/// will still throw if there is no Dart SDK on PATH
///
///
/// If [throwOnError] is given and the command returns a non-zero exit code,
/// the result of [throwOnError] will be thrown regardless of [nothrow]
Future<int> systemDart(
  List<String> args, {
  Directory? workingDirectory,
  bool nothrow = false,
  String Function()? throwOnError,
  ExecOutput output = ExecOutput.mirror,
}) async {
  final systemDartExecutablePath = systemDartExecutable();
  if (systemDartExecutablePath == null) {
    throw "Couldn't find dart executable on PATH.";
  }

  int exitCode = -1;
  try {
    final result = await Exec.run(
      systemDartExecutablePath,
      args,
      workingDirectory: workingDirectory?.path,
      output: output,
      check: !(nothrow || throwOnError != null),
      environment: envs,
      includeParentEnvironment: false,
    );

    exitCode = result.exitCode;
  } on ExecException catch (e) {
    exitCode = e.result.exitCode;
    if (throwOnError == null) {
      rethrow;
    }
  }
  if (exitCode != 0 && throwOnError != null) {
    throw throwOnError();
  }

  return exitCode;
}

String? systemDartExecutable() =>
    // /opt/homebrew/bin/dart
    // Stays on dcli: exec has no synchronous API and this is called from
    // synchronous getters all over sidekick.
    dcli
        .start('which dart', progress: Progress.capture(), nothrow: true)
        .lines
        .firstOrNull;

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

/// Returns the Dart SDK of the `dart` command which was used to launch the test
Directory? testRunnerDartSdk() {
  final executable = Platform.resolvedExecutable;
  final file = File(executable);
  // <somewhere>/dart-sdk/bin/dart
  final realpath = file.resolveSymbolicLinksSync();
  final libexec = File(realpath).parent.parent;
  return libexec;
}

/// Returns the path to Dart SDK of the `dart` which was used to launch the test
String? testRunnerDartSdkPath() => testRunnerDartSdk()?.path;
