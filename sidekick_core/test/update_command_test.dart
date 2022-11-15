import 'dart:io';

import 'package:dartx/dartx_io.dart';
import 'package:dcli/dcli.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/update_command.dart';
import 'package:test/test.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  test('description', () async {
    await insideFakeProjectWithSidekick((projectDir) async {
      final runner =
          initializeSidekick(name: 'dash', dartSdkPath: systemDartSdkPath());

      final toolDir = projectDir.directory('packages/dash/tool');
      expect(toolDir.existsSync(), isFalse);

      final beforeVersion = getCurrentMinimumSidekickCoreVersion();

      runner.addCommand(UpdateCommand());
      await runner.run(['update']);

      final afterVersion = getCurrentMinimumSidekickCoreVersion();
      expect(beforeVersion, lessThan(afterVersion));

      for (final file in [
        'download_dart.sh',
        'install.sh',
        'run.sh',
        'sidekick_config.sh',
      ].map(toolDir.file)) {
        expect(file.existsSync(), isTrue);
      }
    });
  });
}

R insideFakeProjectWithSidekick<R>(R Function(Directory projectDir) block) {
  final tempDir = Directory.systemTemp.createTempSync();
  print(tempDir);
  'git init ${tempDir.path}'.run;

  tempDir.file('pubspec.yaml')
    ..createSync()
    ..writeAsStringSync('name: main_project\n');
  tempDir.file('dash').createSync();

  final fakeSidekickDir = tempDir.directory('packages/dash')
    ..createSync(recursive: true);

  fakeSidekickDir.file('pubspec.yaml')
    ..createSync()
    ..writeAsStringSync('''
name: dash

environment:
  sdk: '>=2.14.0 <3.0.0'

dependencies:
  sidekick_core: 0.7.1
''');
  fakeSidekickDir.directory('lib').createSync();

  env['SIDEKICK_PACKAGE_HOME'] = fakeSidekickDir.absolute.path;
  env['SIDEKICK_ENTRYPOINT_HOME'] = tempDir.absolute.path;

  addTearDown(() {
    tempDir.deleteSync(recursive: true);
    env['SIDEKICK_PACKAGE_HOME'] = null;
    env['SIDEKICK_ENTRYPOINT_HOME'] = null;
  });

  return IOOverrides.runZoned(
    () => block(tempDir),
    getCurrentDirectory: () => tempDir,
  );
}

Version getCurrentMinimumSidekickCoreVersion() {
  final regEx = RegExp(
    '\n  sidekick_core:\\s*[\'"\\^<>= ]*(\\d+\\.\\d+\\.\\d+(?:[+-]\\S+)?)',
  );
  final pubspec = Repository.requiredSidekickPackage.pubspec.readAsStringSync();

  final minVersion =
      regEx.allMatches(pubspec).map((e) => e.group(1)).whereNotNull().single;

  return Version.parse(minVersion);
}
