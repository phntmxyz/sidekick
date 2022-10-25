import 'package:dcli/dcli.dart';
import 'package:dcli/posix.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';

void main() {
  group('systemDartSdkPath', () {
    test('returns null when dart is not on path', () {
      final whichPath =
          start('which which', progress: Progress.capture()).firstLine!;
      PATH.where((p) => !whichPath.startsWith(p)).forEach(env.removeFromPATH);

      expect(systemDartSdkPath(), null);
    });

    test('returns correct path when dart is on path', () {
      final whichPath =
          start('which which', progress: Progress.capture()).firstLine!;
      PATH.where((p) => !whichPath.startsWith(p)).forEach(env.removeFromPATH);

      final tempDir = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final fakeDart = tempDir.file('fake_dart/version/libexec/bin/dart')
        ..createSync(recursive: true);
      chmod(fakeDart.path, permission: '755');
      env.appendToPATH(fakeDart.parent.path);

      expect(
        systemDartSdkPath(),
        tempDir
            .directory('fake_dart/version/libexec')
            .resolveSymbolicLinksSync(),
      );
    });
  });
}
