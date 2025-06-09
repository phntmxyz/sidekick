import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/version_checker.dart';

/// default Dart runtime which is currently used to execute this sidekick CLI
///
/// Can't be final because every test may define a different runtime and it can't
/// be cached per process
SidekickDartRuntime get sidekickDartRuntime =>
    SidekickDartRuntime(SidekickContext.sidekickPackage.root);

/// Version and channel of [sidekickDartRuntime]
final sidekickDartVersion =
    VersionChecker.getDartVersion(sidekickDartRuntime._dartExecutable.path);

/// The bundled Dart runtime of a sidekick CLI
class SidekickDartRuntime {
  /// Use this constructor when operating without a sidekick bash context
  SidekickDartRuntime(this.sidekickPackage);

  /// Location of the package that hosts the runtime
  final Directory sidekickPackage;

  /// The location of the Dart SDK
  Directory get dartSdkPath =>
      sidekickPackage.directory('build/cache/dart-sdk/');

  /// Downloads the SDK
  void download() {
    dcli.run(
      'sh tool/download_dart.sh',
      workingDirectory: sidekickPackage.path,
    );
    assert(isDownloaded(), 'Dart SDK was not downloaded');
  }

  /// True when the SDK is downloaded
  bool isDownloaded() {
    if (!dartSdkPath.existsSync()) {
      return false;
    }
    if (!dartSdkPath.file('bin/dart').existsSync()) {
      return false;
    }
    return true;
  }

  /// Runs custom dart executable of this runtime
  Future<void> dart(
    List<String> args, {
    Directory? workingDirectory,
    dcli.Progress? progress,
    bool nothrow = false,
  }) async {
    dcli.startFromArgs(
      _dartExecutable.path,
      args,
      workingDirectory: workingDirectory?.path,
      progress: progress,
      nothrow: nothrow,
      terminal: progress == null,
    );
  }

  File get _dartExecutable {
    final binDir = dartSdkPath.directory('bin');

    if (Platform.isWindows) {
      return binDir.file('dart.exe');
    } else {
      return binDir.file('dart');
    }
  }
}
