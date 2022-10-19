import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';

import 'init_test.dart';

void main() {
  final dartSdkPath = systemDartSdkPath()?.path;
  final flutterSdkPath = systemFlutterSdkPath()?.path;
  test(
    'dart command works when dartSdkPath is set',
    () async {
      await insideFakeSidekickProject((dir) async {
        final runner = initializeSidekick(
          name: 'dash',
          dartSdkPath: dartSdkPath,
        );
        runner.addCommand(DartCommand());
        await runner.run(['dart']);
      });
    },
    skip: dartSdkPath != null ? null : 'No Dart SDK found on system',
  );

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

  test(
    'dart command links to embedded Dart SDK in Flutter SDK',
    () async {
      await insideFakeSidekickProject((dir) async {
        final runner = initializeSidekick(
          name: 'dash',
          flutterSdkPath: flutterSdkPath,
        );
        runner.addCommand(DartCommand());
        await runner.run(['dart']);
      });
    },
    skip: flutterSdkPath != null ? null : 'No Flutter SDK found on system',
  );
}

Directory? systemFlutterSdkPath() {
  // Get path from "flutter doctor -v" printing the line
  //     • Flutter version 2.2.0-10.1.pre at /usr/local/Caskroom/flutter/latest/flutter
  final lines =
      dcli.start('flutter doctor -v', progress: dcli.Progress.capture()).lines;
  final flutterRepoPath = lines
      .firstWhere((line) => line.contains("Flutter version"))
      .split(" ")
      .lastOrNull;
  if (flutterRepoPath == null) {
    return null;
  }
  return Directory(flutterRepoPath);
}

Directory? systemDartSdkPath() {
  return systemFlutterSdkPath()?.directory('bin/cache/dart-sdk');
}
