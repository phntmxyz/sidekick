import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';

import 'dart_command_test.dart';
import 'init_test.dart';

void main() {
  final flutterSdkPath = systemFlutterSdkPath()?.path;
  test(
    'flutter command works when dartSdkPath is set',
    () async {
      await insideFakeSidekickProject((dir) async {
        final runner = initializeSidekick(
          name: 'dash',
          flutterSdkPath: flutterSdkPath,
        );
        runner.addCommand(FlutterCommand());
        await runner.run(['flutter']);
      });
    },
    skip: flutterSdkPath != null ? null : 'no Dart SDK found on system',
  );

  test('flutter command fails when dartSdkPath is not set', () async {
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
