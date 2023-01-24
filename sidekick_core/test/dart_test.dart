import 'package:dcli/dcli.dart';
import 'package:dcli/posix.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  group('systemDartSdkPath', () {
    final originalPATH = [...PATH];
    setUp(() {
      final whichPath =
          start('which which', progress: Progress.capture()).firstLine!;
      PATH.where((p) => !whichPath.startsWith(p)).forEach(env.removeFromPATH);
      addTearDown(() {
        PATH.forEach(env.removeFromPATH);
        originalPATH.forEach(env.appendToPATH);
      });
    });

    test('returns null when dart is not on path', () {
      expect(systemDartSdkPath(), null);
    });

    test('returns correct path when dart is on path', () {
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

  group('dart', () {
    test(
      'throws by default when command fails',
      () async {
        await insideFakeProjectWithSidekick((_) async {
          final runner = initializeSidekick(
            name: 'dash',
            dartSdkPath: fakeFailingDartSdk().path,
          );
          runner.addCommand(
            DelegatedCommand(name: 'dart', block: () => dart(['fail'])),
          );

          await expectLater(
            () => runner.run(['dart']),
            throwsA(isA<RunException>()),
          );
        });
      },
    );

    test(
      'throws given message when command fails',
      () async {
        await insideFakeProjectWithSidekick((_) async {
          final runner = initializeSidekick(
            name: 'dash',
            dartSdkPath: fakeFailingDartSdk().path,
          );
          runner.addCommand(
            DelegatedCommand(
              name: 'dart',
              block: () => dart(['fail'], throwOnError: (_) => 'foo'),
            ),
          );

          await expectLater(
            () => runner.run(['dart']),
            throwsA('foo'),
          );
        });
      },
    );
  });
}
