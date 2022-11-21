import 'dart:async';

import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/update_command.dart';
import 'package:sidekick_core/src/sidekick_version_checker.dart';
import 'package:test/test.dart';

import 'util/local_testing.dart';

void main() {
  test('UpdateCommand generates new files', () async {
    final printLog = <String>[];
    // override print to verify output
    final spec = ZoneSpecification(
      print: (_, __, ___, line) => printLog.add(line),
    );
    await Zone.current.fork(specification: spec).run(() async {
      await insideFakeProjectWithSidekick((projectDir) async {
        final sidekickDir = projectDir.directory('packages/dash');
        final expectedFilesToGenerate = [
          'tool/download_dart.sh',
          'tool/install.sh',
          'tool/run.sh',
          'tool/sidekick_config.sh',
        ].map(sidekickDir.file);

        for (final file in expectedFilesToGenerate) {
          expect(
            !file.existsSync() || file.readAsStringSync().isEmpty,
            isTrue,
            reason: '${file.path} exists or is not empty',
          );
        }

        final runner = initializeSidekick(
          name: 'dash',
          dartSdkPath: systemDartSdkPath(),
        );

        runner.addCommand(UpdateCommand());
        await runner.run(['update']);

        const versionChecker = SidekickVersionChecker();

        final sidekickVersionAfterUpdate = versionChecker
            .getCurrentMinimumPackageVersion(['sidekick', 'generator_version']);
        final sidekickCoreVersionAfterUpdate = versionChecker
            .getCurrentMinimumPackageVersion(['dependencies', 'sidekick_core']);
        final latestSidekickVersion =
            await versionChecker.getLatestPackageVersion('sidekick');
        final latestSidekickCoreVersion =
            await versionChecker.getLatestPackageVersion('sidekick_core');

        expect(sidekickVersionAfterUpdate, latestSidekickVersion);
        expect(sidekickCoreVersionAfterUpdate, latestSidekickCoreVersion);

        for (final file in expectedFilesToGenerate) {
          expect(
            file.existsSync() && file.readAsStringSync().isNotEmpty,
            isTrue,
            reason: '${file.path} does not exist or is empty',
          );
        }

        expect(
          printLog,
          containsAllInOrder([
            grey(
              'Updating sidekick CLI dash from version 0.0.0 to $latestSidekickVersion ...',
            ),
            green(
              'Successfully updated sidekick CLI dash from version 0.0.0 to $latestSidekickVersion!',
            ),
          ]),
        );
      });
    });
  });
}

R insideFakeProjectWithSidekick<R>(R Function(Directory projectDir) block) {
  final tempDir = Directory.systemTemp.createTempSync();
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
  sidekick_core: 0.0.0

sidekick:
  generator_version: 0.0.0
''');

  final fakeSidekickLibDir = fakeSidekickDir.directory('lib')..createSync();

  fakeSidekickLibDir.file('src/dash_project.dart').createSync(recursive: true);
  fakeSidekickLibDir.file('dash_sidekick.dart').createSync();

  overrideSidekickCoreWithLocalPath(fakeSidekickDir);

  env['SIDEKICK_PACKAGE_HOME'] = fakeSidekickDir.absolute.path;
  env['SIDEKICK_ENTRYPOINT_HOME'] = tempDir.absolute.path;

  overrideSidekickDartRuntimeWithSystemDartRuntime(fakeSidekickDir);

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
