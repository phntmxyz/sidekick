import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';

import 'fake_sdk.dart';
import 'init_test.dart';

void main() {
  test('dart command works when dartSdkPath is set', () async {
    await insideFakeSidekickProject((dir) async {
      final runner = initializeSidekick(
        name: 'dash',
        dartSdkPath: fakeDartSdk().path,
      );
      runner.addCommand(DartCommand());
      await runner.run(['dart']);
    });
  });

  test('dart command fails when dartSdkPath is not set', () async {
    await insideFakeSidekickProject((dir) async {
      final runner = initializeSidekick(
        name: 'dash',
        // ignore: avoid_redundant_argument_values
        dartSdkPath: null,
      );
      runner.addCommand(DartCommand());
      try {
        await runner.run(['dart']);
        fail('did not throw');
      } catch (e) {
        expect(e, isA<DartSdkNotSetException>());
      }
    });
  });

  test('dart command links to embedded Dart SDK in Flutter SDK', () async {
    await insideFakeSidekickProject((dir) async {
      final runner = initializeSidekick(
        name: 'dash',
        flutterSdkPath: fakeFlutterSdk().path,
      );
      runner.addCommand(DartCommand());
      await runner.run(['dart']);
    });
  });
}

Future<File> installFlutterWrapper(Directory directory) async {
  writeAndRunShellScript(
    r'sh -c "$(curl -fsSL https://raw.githubusercontent.com/passsy/flutter_wrapper/master/install.sh)"',
    workingDirectory: directory,
  );
  final exe = directory.file('flutterw');
  assert(exe.existsSync());
  return exe;
}
