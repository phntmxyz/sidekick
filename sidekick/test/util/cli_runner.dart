import 'package:dcli/dcli.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/scaffolding.dart';
import 'package:test_process/test_process.dart';

/// Creates the sidekick cli in a separate temp directory with linked
/// dependencies to the local sidekick_core
Future<SidekickCli> buildSidekickCli() async {
  final original = Directory('.');
  final copy = Directory.systemTemp.createTempSync();
  print('path to sidekick cli');
  print(copy.path);
  // TODO undo addTearDown(() => copy.deleteSync(recursive: true));
  await original.copyRecursively(copy);

  overrideSidekickCoreWithLocalPath(copy);

  // remove local dependency on sidekick_test, it breaks because of the
  // relative path but can be safely removed because it's just a dev_dependency
  systemDart(['pub', 'remove', 'sidekick_test'], workingDirectory: copy);

  final lockFile = copy.file('pubspec.lock');
  if (lockFile.existsSync()) {
    lockFile.deleteSync();
  }
  final dartToolDir = copy.directory('.dart_tool');
  if (dartToolDir.existsSync()) {
    dartToolDir.deleteSync(recursive: true);
  }

  startFromArgs('dart', ['pub', 'get'], workingDirectory: copy.path);
  print('created sidekick cli in ${copy.path}');

  return SidekickCli._(copy);
}

/// Copy of package:sidekick in temp directory.
///
/// Might contain changes compared to code in <repo>/sidekick for testing like
/// local path dependencies
class SidekickCli {
  final Directory root;

  SidekickCli._(this.root);

  Future<TestProcess> run(
    List<String> args, {
    required Directory workingDirectory,
  }) async {
    return TestProcess.start(
      'dart',
      [root.file('bin/sidekick.dart').path, ...args],
      workingDirectory: workingDirectory.path,
    );
  }
}
