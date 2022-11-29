import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  test('dart command works when dartSdkPath is set', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final runner = initializeSidekick(
        name: 'dash',
        dartSdkPath: fakeDartSdk().path,
      );
      runner.addCommand(DartCommand());
      await runner.run(['dart']);
    });
  });

  test('dart command fails when dartSdkPath is not set', () async {
    await insideFakeProjectWithSidekick((dir) async {
      final runner = initializeSidekick(
        name: 'dash',
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
        name: 'dash',
        flutterSdkPath: fakeFlutterSdk().path,
      );
      runner.addCommand(DartCommand());
      await runner.run(['dart']);
    });
  });
}
