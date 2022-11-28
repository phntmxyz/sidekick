import 'package:dcli/dcli.dart';
import 'package:dcli/posix.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';

void main() {
  final tempDir = Directory.systemTemp.createTempSync();
  final fakeFlutter = tempDir.file('fake_flutter/bin/flutter')
    ..createSync(recursive: true);
  chmod(fakeFlutter.path, permission: '755');

  setUp(() {
    final whichPath =
        start('which which', progress: Progress.capture()).firstLine!;
    PATH.where((p) => !whichPath.startsWith(p)).forEach(env.removeFromPATH);
    env['FLUTTER_ROOT'] = null;
  });

  tearDownAll(() {
    tempDir.deleteSync(recursive: true);
  });

  group('systemFlutterSdkPath', () {
    test('returns null when flutter is not on path or env.FLUTTER_ROOT', () {
      expect(systemFlutterSdkPath(), null);
    });

    test('prioritizes flutter from path over env.FLUTTER_ROOT', () {
      env['FLUTTER_ROOT'] = '/foo/flutter';
      env.appendToPATH(fakeFlutter.parent.path);

      expect(
        systemFlutterSdkPath(),
        tempDir.directory('fake_flutter').resolveSymbolicLinksSync(),
      );
    });

    test('returns correct path when env.FLUTTER_ROOT is defined', () {
      env['FLUTTER_ROOT'] = fakeFlutter.path;

      expect(
        systemFlutterSdkPath(),
        tempDir.directory('fake_flutter').resolveSymbolicLinksSync(),
      );
    });
  });
}
