import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';

import 'fake_sdk.dart';
import 'init_test.dart';

void main() {
  test(
    'flutter command works when flutterSdkPath is set',
    () async {
      await insideFakeSidekickProject((dir) async {
        final runner = initializeSidekick(
          name: 'dash',
          flutterSdkPath: fakeFlutterSdk().path,
        );
        runner.addCommand(FlutterCommand());
        await runner.run(['flutter']);
      });
    },
  );

  test('flutter command fails when flutterSdkPath is not set', () async {
    await insideFakeSidekickProject((dir) async {
      final runner = initializeSidekick(
        name: 'dash',
        // ignore: avoid_redundant_argument_values
        flutterSdkPath: null,
      );
      runner.addCommand(FlutterCommand());
      try {
        await runner.run(['flutter']);
        fail('did not throw');
      } catch (e) {
        expect(e, isA<FlutterSdkNotSetException>());
      }
    });
  });
}
