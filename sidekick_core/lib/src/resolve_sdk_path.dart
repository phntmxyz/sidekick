part of '../sidekick_core.dart';

/// Transforms [sdkPath] to an absolute directory
///
/// This is to make passing `flutterSdkPath`/`dartSdkPath`
/// in `initializeSidekick` a relative path work from anywhere.
///
/// If [sdkPath] is a relative path, it is resolved relative from
/// the project root.
///
/// Throws a [SdkNotFoundException] if [sdkPath] is given but no
/// existing directory can be found.
Directory? _resolveSdkPath(String? sdkPath) {
  if (sdkPath == null) {
    return null;
  }
  final dir = Directory(sdkPath);

  final resolvedDir = dir.isAbsolute
      ? dir
      // resolve relative path relative from project root
      : Repository
          // /Users/foo/project-x/packages/custom_sidekick
          .requiredCliPackage
          // /Users/foo/project-x/packages
          .parent
          // /Users/foo/project-x
          .parent
          .directory(sdkPath);

  if (!resolvedDir.existsSync()) {
    throw SdkNotFoundException(sdkPath);
  }

  return resolvedDir;
}

/// The Dart or Flutter SDK path is set in [initializeSidekick],
/// but the directory doesn't exist
class SdkNotFoundException implements Exception {
  SdkNotFoundException(this.sdkPath);

  final String sdkPath;

  late final String message =
      "Dart or Flutter SDK set to '$sdkPath', but that directory doesn't exist. "
      "Please fix the path in `initializeSidekick` (dartSdkPath/flutterSdkPath).";

  @override
  String toString() {
    return "SdkNotFoundException{message: $message}";
  }
}
