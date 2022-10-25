import 'package:dcli/dcli.dart';
import 'package:dcli/posix.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';

void main() {
  group('systemFlutterSdkPath', () {
    test('returns null when flutter is not on path', () {
      final whichPath =
          start('which which', progress: Progress.capture()).firstLine!;
      PATH.where((p) => !whichPath.startsWith(p)).forEach(env.removeFromPATH);

      expect(systemFlutterSdkPath(), null);
    });

    test('returns correct path when flutter is on path', () {
      final whichPath =
          start('which which', progress: Progress.capture()).firstLine!;
      PATH.where((p) => !whichPath.startsWith(p)).forEach(env.removeFromPATH);

      final tempDir = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final fakeFlutter = tempDir.file('fake_flutter/bin/flutter')
        ..createSync(recursive: true);
      chmod(fakeFlutter.path, permission: '755');
      env.appendToPATH(fakeFlutter.parent.path);

      expect(
        systemFlutterSdkPath(),
        tempDir.directory('fake_flutter').resolveSymbolicLinksSync(),
      );
    });
  });
}
