import 'dart:async';

import 'package:sidekick_core/sidekick_core.dart';

/// Registers an initializer function that is called before executing the [flutter] and [dart] commands
/// to prepare the SDKs, such as downloading it.
///
/// Also this function will be called multiple times, once for each usage of the [flutter]/[dart] method
Removable addSdkInitializer(SdkInitializer initializer) {
  if (!_sdkInitializers.contains(initializer)) {
    _sdkInitializers.add(initializer);
  }
  return () => _sdkInitializers.remove(initializer);
}

/// Can be called to remove a listener
typedef Removable = void Function();

/// Called by [flutter] before executing the flutter executable
typedef SdkInitializer = FutureOr<void> Function(SdkInitializerContext context);

/// Initializers that have to be executed before executing the flutter command
List<SdkInitializer> _sdkInitializers = [];

/// Calls all registered Flutter/Dart SDK initializers
///
/// The [workingDirectory] is the directory where the [flutter]/[dart] commands are executed.
/// The enclosing Dart package will be used to determine the Flutter/Dart SDK version.
Future<void> initializeSdkForPackage(
  Directory? workingDirectory,
) async {
  final where = workingDirectory ?? entryWorkingDirectory;

  final Directory? packageDir =
      where.findParent((dir) => DartPackage.fromDirectory(dir) != null);

  final context = SdkInitializerContext(
    flutterSdk: flutterSdk,
    dartSdk: dartSdk,
    packageDir:
        packageDir != null ? DartPackage.fromDirectory(packageDir) : null,
    workingDirectory: where,
  );
  for (final initializer in _sdkInitializers) {
    try {
      await initializer(context);
    } catch (e, stack) {
      printerr("Error initializing SDKs:\n$e");
      printerr(stack);
    }
  }
}

/// Called by [flutter] before executing the flutter executable
/// Called by [dart] before executing the dart executable
class SdkInitializerContext {
  SdkInitializerContext({
    this.flutterSdk,
    this.dartSdk,
    this.packageDir,
    this.workingDirectory,
  });

  /// The Flutter SDK directory, this directory is set by flutterSdkPath in [initializeSidekick]
  /// Make sure the SDK will be initialized in this directory
  ///
  /// You may want to use a symlink to the actual SDK directory
  ///
  /// `null` when the Flutter SDK is not required
  final Directory? flutterSdk;

  /// The Dart SDK directory, this directory is set by dartSdkPath in [initializeSidekick]
  /// Make sure the SDK will be initialized in this directory
  ///
  /// You may want to use a symlink to the actual SDK directory
  ///
  /// `null` when the Dart SDK is not required
  final Directory? dartSdk;

  /// The package directory where the [flutter] or [dart] command is executed
  /// which follows directly after this initialization
  final DartPackage? packageDir;

  /// The directory the [flutter] or [dart] command will be executed in
  final Directory? workingDirectory;
}
