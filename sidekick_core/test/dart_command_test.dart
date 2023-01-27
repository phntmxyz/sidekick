import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  test('dart command works when dartSdkPath is set', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final runner = initializeSidekick(
        dartSdkPath: fakeDartSdk().path,
      );
      runner.addCommand(DartCommand());
      await runner.run(['dart']);
    });
  });

  test('dart command fails when dartSdkPath is not set', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final runner = initializeSidekick(
        // ignore: avoid_redundant_argument_values
        dartSdkPath: null,
      );
      runner.addCommand(DartCommand());
      expect(
        () => runner.run(['dart']),
        throwsA(isA<DartSdkNotSetException>()),
      );
    });
  });

  test('dart command links to embedded Dart SDK in Flutter SDK', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final runner = initializeSidekick(
        flutterSdkPath: fakeFlutterSdk().path,
      );
      runner.addCommand(DartCommand());
      await runner.run(['dart']);
    });
  });

  test('dart command sets exit code when command fails', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final runner = initializeSidekick(
        dartSdkPath: fakeFailingDartSdk().path,
      );
      runner.addCommand(DartCommand());
      await runner.run(['dart', 'plz', 'fail']);
      expect(exitCode, isNonZero);
    });
  });
}
