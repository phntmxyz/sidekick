import 'dart:async';

import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/update_command.dart';
import 'package:sidekick_core/src/pub/dart_archive.dart';
import 'package:sidekick_core/src/version_checker.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  for (final sidekickCliVersion in [null, "0.0.0"]) {
    test(
        'UpdateCommand generates new files when current '
        'sidekick cli version is $sidekickCliVersion', () async {
      final printLog = <String>[];
      Future<void> code(Directory projectDir) async {
        final sidekickDir = projectDir.directory('packages/dash');
        final expectedFilesToGenerate = [
          'tool/install.sh',
          'tool/run.sh',
        ].map(sidekickDir.file);

        for (final file in expectedFilesToGenerate) {
          expect(
            !file.existsSync() || file.readAsStringSync().isEmpty,
            isTrue,
            reason: '${file.path} exists or is not empty',
          );
        }

        final runner = initializeSidekick(
          dartSdkPath: systemDartSdkPath(),
        );

        final targetVersion = Version(1, 1, 0);

        runner.addCommand(UpdateCommand());
        await runner.run(['update', targetVersion.toString()]);

        final package = SidekickContext.sidekickPackage;
        final sidekickVersionAfterUpdate =
            VersionChecker.getMinimumVersionConstraint(
          package,
          ['sidekick', 'cli_version'],
        );
        final sidekickCoreVersionAfterUpdate =
            VersionChecker.getMinimumVersionConstraint(
          package,
          ['dependencies', 'sidekick_core'],
        );

        expect(sidekickVersionAfterUpdate, targetVersion);
        expect(sidekickCoreVersionAfterUpdate, targetVersion);

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
            'Updating sidekick CLI dash from version 0.0.0 to $targetVersion ...',
            green(
              'Successfully updated sidekick CLI dash from version 0.0.0 to $targetVersion!',
            ),
          ]),
        );
      }

      await runZoned(
        () => insideFakeProjectWithSidekick(
          code,
          overrideSidekickCoreWithLocalDependency: true,
          sidekickCliVersion: sidekickCliVersion,
        ),
        zoneSpecification: ZoneSpecification(
          print: (_, __, ___, line) {
            printLog.add(line);
            stdout.writeln(line);
          },
        ),
      );
    });
  }

  test('UpdateCommand does not downgrade', () async {
    final printLog = <String>[];

    Future<void> code(Directory projectDir) async {
      final runner = initializeSidekick(
        dartSdkPath: systemDartSdkPath(),
      );

      runner.addCommand(UpdateCommand());
      await runner.run(['update', '1.0.0']);

      final package = SidekickContext.sidekickPackage;
      final sidekickVersionAfterUpdate =
          VersionChecker.getMinimumVersionConstraint(
        package,
        ['sidekick', 'cli_version'],
      );
      final sidekickCoreVersionAfterUpdate =
          VersionChecker.getMinimumVersionConstraint(
        package,
        ['dependencies', 'sidekick_core'],
      );
      expect(sidekickVersionAfterUpdate, Version(1, 1, 0));
      expect(sidekickCoreVersionAfterUpdate, Version(1, 1, 0));

      expect(
        printLog,
        contains('No need to update because you are already using the '
            'latest sidekick cli version.'),
      );
    }

    await runZoned(
      () async {
        await insideFakeProjectWithSidekick(
          code,
          overrideSidekickCoreWithLocalDependency: true,
          sidekickCliVersion: '1.1.0',
          sidekickCoreVersion: '1.1.0',
        );
      },
      zoneSpecification: ZoneSpecification(
        print: (_, __, ___, line) {
          printLog.add(line);
          stdout.writeln(line);
        },
      ),
    );
  });

  test('UpdateCommand executes update script with downloaded Dart SDK',
      () async {
    final printLog = <String>[];

    Future<void> code(Directory projectDir) async {
      VersionChecker.testFakeGetLatestDependencyVersion = (
        String dependency, {
        Version? dartSdkVersion,
      }) async {
        if (dependency == 'sidekick_core') {
          if (dartSdkVersion == null) {
            return Version(2, 0, 0);
          }
          // TODO make update to 3.0 a separate test
          if (dartSdkVersion >= Version(3, 0, 0)) {
            // update to Dart 3.0.0 not yet possible
            return null;
          }
          if (dartSdkVersion >= Version(2, 0, 0)) {
            return Version(1, 2, 0);
          }
        }
        throw 'unknown dependency $dependency';
      };
      addTearDown(
        () => VersionChecker.testFakeGetLatestDependencyVersion = null,
      );

      final runner = initializeSidekick(
        dartSdkPath: systemDartSdkPath(),
      );

      runner.addCommand(UpdateCommand()..dartArchive = MockDartArchive());
      // TODO fake the sidekick_core downloading from pub.dev and inject a custom update script (update_sidekick_cli.dart)
      // which prints the input information and does update sidekick_core
      await runner.run(['update']);

      final cliPackage = SidekickContext.sidekickPackage;
      final sidekickVersionAfterUpdate =
          VersionChecker.getMinimumVersionConstraint(
        cliPackage,
        ['sidekick', 'cli_version'],
      );
      expect(sidekickVersionAfterUpdate, Version(1, 2, 0));

      final updatePackage = DartPackage.fromDirectory(
        cliPackage.buildDir.directory('update_1_2_0'),
      )!;

      final dartSdkConstraint = VersionChecker.getMinimumVersionConstraint(
        updatePackage,
        ['environment', 'sdk'],
      );
      expect(dartSdkConstraint, Version.parse('2.19.6'));

      final dartSdkPath = cliPackage.buildDir.directory('cache/dart-sdk');
      final versionFile = dartSdkPath.file('version');
      final dartSdkVersion =
          Version.parse(versionFile.readAsStringSync().trim());
      expect(dartSdkVersion, Version.parse('2.19.6'));
    }

    await runZoned(
      () async {
        await insideFakeProjectWithSidekick(
          code,
          overrideSidekickCoreWithLocalDependency: true,
          sidekickCliVersion: '1.1.0',
          sidekickCoreVersion: '1.1.0',
        );
      },
      zoneSpecification: ZoneSpecification(
        print: (_, __, ___, line) {
          printLog.add(line);
          stdout.writeln(line);
        },
      ),
    );
  });
}

class MockDartArchive implements DartArchive {
  @override
  Stream<Version> getLatestDartVersions() async* {
    final versions = [Version(2, 19, 2), Version(2, 19, 6), Version(3, 0, 0)];
    for (final v in versions) {
      yield v;
    }
  }
}
