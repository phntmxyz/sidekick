import 'dart:async';

import 'package:pub_semver/pub_semver.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/commands/update_command.dart';
import 'package:sidekick_core/src/pub/dart_archive.dart';
import 'package:sidekick_core/src/template/update_executor.template.dart';
import 'package:sidekick_core/src/version_checker.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  for (final sidekickCliVersion in [null, "0.0.0"]) {
    test(
        'UpdateCommand generates new tool/ files when current '
        'sidekick cli version is $sidekickCliVersion', () async {
      final printLog = <String>[];

      VersionChecker.testFakeGetLatestDependencyVersion = (
        String dependency, {
        Version? dartSdkVersion,
      }) async {
        if (dependency == 'sidekick_core') {
          if (dartSdkVersion == null) {
            return Version(2, 0, 0);
          }
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
      UpdateExecutorTemplate.testFakeCreateUpdateExecutorTemplate = ({
        required Directory location,
        required Version dartSdkVersion,
        required Version newSidekickCoreVersion,
        required Version oldSidekickCoreVersion,
      }) {
        return LocalUpdateExecutorTemplate(
          location: location,
          dartSdkVersion: dartSdkVersion,
          newSidekickCoreVersion: newSidekickCoreVersion,
          oldSidekickCoreVersion: oldSidekickCoreVersion,
        );
      };
      addTearDown(() {
        return UpdateExecutorTemplate.testFakeCreateUpdateExecutorTemplate =
            null;
      });

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

        final targetVersion = Version(1, 2, 0);

        runner.addCommand(UpdateCommand()..dartArchive = MockDartArchive());
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

  test('UpdateCommand does not update when no update exists', () async {
    final updateCommand = UpdateCommandTestCase(
      initialSidekickCliVersion: Version.parse('1.1.0'),
      initialSidekickCoreVersion: Version.parse('1.1.0'),
      sidekickCoreReleases: [
        sidekick_core('1.1.0', sdk: '>=2.12.0 <3.0.0'),
      ],
      dartSdkVersion: Version.parse('2.19.6'),
      dartSdks: [
        Version.parse('2.18.0'),
        Version.parse('2.19.2'),
        Version.parse('2.19.6'),
      ],
    );
    await updateCommand.execute(() async {
      await updateCommand.update();

      expect(
        updateCommand.printLog,
        contains('No need to update because you are already using the latest '
            'sidekick_core:1.1.0 version for Dart 2.19.6.'),
      );
      expect(updateCommand.sidekickCliVersion, Version.parse('1.1.0'));
      expect(updateCommand.sidekickCoreVersion, Version.parse('1.1.0'));
    });
  });

  test('UpdateCommand updates the dart sdk', () async {
    final updateCommand = UpdateCommandTestCase(
      initialSidekickCliVersion: Version.parse('1.1.0'),
      initialSidekickCoreVersion: Version.parse('1.1.0'),
      sidekickCoreReleases: [
        sidekick_core('1.1.0', sdk: '>=2.12.0 <3.0.0'),
      ],
      dartSdks: [
        Version.parse('2.18.0'),
        Version.parse('2.19.1'),
      ],
    );
    await updateCommand.execute(() async {
      await updateCommand.update();
      expect(
        updateCommand.printLog,
        contains('Successfully updated the Dart SDK to 2.19.1.'),
      );
      expect(updateCommand.downloadedDartSdkVersion, Version.parse('2.19.1'));
    });
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
      UpdateExecutorTemplate.testFakeCreateUpdateExecutorTemplate = ({
        required Directory location,
        required Version dartSdkVersion,
        required Version newSidekickCoreVersion,
        required Version oldSidekickCoreVersion,
      }) {
        return _PrintOnlyUpdateExecutorTemplate(
          location: location,
          dartSdkVersion: dartSdkVersion,
          newSidekickCoreVersion: newSidekickCoreVersion,
          oldSidekickCoreVersion: oldSidekickCoreVersion,
        );
      };
      addTearDown(() {
        return UpdateExecutorTemplate.testFakeCreateUpdateExecutorTemplate =
            null;
      });

      final runner = initializeSidekick(
        dartSdkPath: systemDartSdkPath(),
      );

      runner.addCommand(UpdateCommand()..dartArchive = MockDartArchive());
      await runner.run(['update']);

      // Dart SDK has been updated
      final dartSdkPath =
          SidekickContext.sidekickPackage.buildDir.directory('cache/dart-sdk');
      final versionFile = dartSdkPath.file('version');
      final dartSdkVersion =
          Version.parse(versionFile.readAsStringSync().trim());
      expect(dartSdkVersion, Version.parse('2.19.6'));

      // Correct arguments have been injected
      expect(printLog, contains('Arguments: [dash, 1.1.0, 1.2.0]'));

      // Update script has been executed with correct Dart SDK
      final fullLog = printLog.join('\n');
      expect(fullLog, contains('Downloading Dart SDK 2.19.6'));
      expect(fullLog, contains('Dart Version: 2.19.6'));
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

// ignore: non_constant_identifier_names
PublishedPackage sidekick_core(
  String version, {
  required String sdk,
}) {
  return PublishedPackage(
    name: 'sidekick_core',
    version: Version.parse(version),
    dartSdkConstraint: VersionConstraint.parse(sdk),
  );
}

class PublishedPackage {
  final String name;
  final Version version;
  final VersionConstraint dartSdkConstraint;

  PublishedPackage({
    required this.name,
    required this.version,
    required this.dartSdkConstraint,
  });
}

class UpdateCommandTestCase {
  final Version? initialSidekickCliVersion;
  final Version? initialSidekickCoreVersion;

  final List<PublishedPackage> sidekickCoreReleases;
  final List<Version> dartSdks;
  final Version? dartSdkVersion;

  UpdateCommandTestCase({
    this.initialSidekickCliVersion,
    this.initialSidekickCoreVersion,
    required this.sidekickCoreReleases,
    required this.dartSdks,
    this.dartSdkVersion,
  });

  final printLog = <String>[];
  final command = UpdateCommand();
  Directory get projectDir => _projectDir!;
  Directory? _projectDir;

  Version? get downloadedDartSdkVersion {
    final dartSdkPath =
        SidekickContext.sidekickPackage.buildDir.directory('cache/dart-sdk');
    final versionFile = dartSdkPath.file('version');
    try {
      return Version.parse(versionFile.readAsStringSync().trim());
    } catch (_) {
      return null;
    }
  }

  Version? get sidekickCliVersion {
    final package = SidekickContext.sidekickPackage;
    return VersionChecker.getMinimumVersionConstraint(
      package,
      ['sidekick', 'cli_version'],
    );
  }

  Version? get sidekickCoreVersion {
    final package = SidekickContext.sidekickPackage;
    return VersionChecker.getMinimumVersionConstraint(
      package,
      ['dependencies', 'sidekick_core'],
    );
  }

  Future<void> update([List<String> args = const []]) async {
    final runner = initializeSidekick(
      dartSdkPath: systemDartSdkPath(),
    );

    final archive = MockDartArchive();
    archive.versions.clear();
    archive.versions.addAll(dartSdks);
    runner.addCommand(command..dartArchive = archive);

    await runner.run(['update', ...args]);
  }

  Future<void> execute(Future<void> Function() code) async {
    await runZoned(
      () async {
        VersionChecker.testFakeGetLatestDependencyVersion = (
          String dependency, {
          Version? dartSdkVersion,
        }) async {
          if (dependency == 'sidekick_core') {
            final latest = sidekickCoreReleases.where((package) {
              if (dartSdkVersion == null) return true;
              return package.dartSdkConstraint.allows(dartSdkVersion);
            }).maxBy((version) => version.version);
            return latest?.version;
          }
          throw 'unknown dependency $dependency';
        };
        addTearDown(
          () => VersionChecker.testFakeGetLatestDependencyVersion = null,
        );

        final sdk = dartSdkVersion ?? dartSdks.first;

        await insideFakeProjectWithSidekick(
          (dir) async {
            _projectDir = dir;
            await code();
          },
          dartSdkConstraint: '>=$sdk <${sdk.nextBreaking}',
          overrideSidekickCoreWithLocalDependency: true,
          sidekickCliVersion: initialSidekickCliVersion?.toString() ?? '1.1.0',
          sidekickCoreVersion:
              initialSidekickCoreVersion?.toString() ?? '1.1.0',
        );
      },
      zoneSpecification: ZoneSpecification(
        print: (_, __, ___, line) {
          printLog.add(line);
          stdout.writeln(line);
        },
      ),
    );
  }
}

class MockDartArchive implements DartArchive {
  final versions = [Version(2, 19, 2), Version(2, 19, 6), Version(3, 0, 0)];
  @override
  Stream<Version> getLatestDartVersions() async* {
    for (final v in versions) {
      yield v;
    }
  }
}

/// Does not actually update anything, but prints the information injected into the update script
class _PrintOnlyUpdateExecutorTemplate
    with Fake
    implements UpdateExecutorTemplate {
  _PrintOnlyUpdateExecutorTemplate({
    required this.location,
    required this.dartSdkVersion,
    required this.oldSidekickCoreVersion,
    required this.newSidekickCoreVersion,
  });

  @override
  final Directory location;
  @override
  final Version dartSdkVersion;
  @override
  final Version oldSidekickCoreVersion;
  @override
  final Version newSidekickCoreVersion;

  @override
  void generate() {
    location.file('pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
name: fake_update
environment:
  sdk: '>=${dartSdkVersion.canonicalizedVersion} <${dartSdkVersion.nextBreaking.canonicalizedVersion}'
''');

    location.file('bin/update.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'dart:io';

Future<void> main(List<String> args) async {
  print('Arguments: \${args}');
  print('Dart Version: \${Platform.version}');
}
  ''');
  }
}

class LocalUpdateExecutorTemplate extends UpdateExecutorTemplate {
  LocalUpdateExecutorTemplate({
    required Directory location,
    required Version dartSdkVersion,
    required Version oldSidekickCoreVersion,
    required Version newSidekickCoreVersion,
  }) : super.raw(
          location: location,
          dartSdkVersion: dartSdkVersion,
          oldSidekickCoreVersion: oldSidekickCoreVersion,
          newSidekickCoreVersion: newSidekickCoreVersion,
        );

  @override
  void generate() {
    super.generate();
    overrideSidekickCoreWithLocalPath(location);
  }
}
