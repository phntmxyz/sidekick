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
  test('Generates files in /tool folder', () async {
    final testCase = _UpdateCommandTestCase(
      initialSidekickCliVersion: Version.parse('1.1.0'),
      initialSidekickCoreVersion: Version.parse('1.1.0'),
      sidekickCoreReleases: [
        _sidekick_core('1.2.0', sdk: '>=2.12.0 <3.0.0'),
      ],
    );
    await testCase.execute((command) async {
      final sidekickDir = testCase.projectDir.directory('packages/dash')
        ..verifyExistsOrThrow();
      final installSh = sidekickDir.file('tool/install.sh');
      final runSh = sidekickDir.file('tool/run.sh');

      await command.update();

      expect(installSh.existsSync(), isTrue);
      expect(runSh.existsSync(), isTrue);
    });
  });

  test('UpdateCommand does not update when no update exists', () async {
    final testCase = _UpdateCommandTestCase(
      initialSidekickCliVersion: Version.parse('1.1.0'),
      initialSidekickCoreVersion: Version.parse('1.1.0'),
      sidekickCoreReleases: [
        _sidekick_core('1.1.0', sdk: '>=2.12.0 <3.0.0'),
      ],
      dartSdkVersion: Version.parse('2.19.6'),
      dartSdks: [
        Version.parse('2.18.0'),
        Version.parse('2.19.2'),
        Version.parse('2.19.6'),
      ],
    );
    await testCase.execute((command) async {
      await command.update();

      expect(
        testCase.printLog,
        contains('No need to update because you are already using the latest '
            'sidekick_core:1.1.0 version for Dart 2.19.6.'),
      );
      expect(testCase.sidekickCliVersion, Version.parse('1.1.0'));
      expect(testCase.sidekickCoreVersion, Version.parse('1.1.0'));
    });
  });

  test('UpdateCommand updates the dart sdk', () async {
    final testCase = _UpdateCommandTestCase(
      initialSidekickCliVersion: Version.parse('1.1.0'),
      initialSidekickCoreVersion: Version.parse('1.1.0'),
      sidekickCoreReleases: [
        _sidekick_core('1.1.0', sdk: '>=2.12.0 <3.0.0'),
      ],
      dartSdks: [
        Version.parse('2.18.0'),
        Version.parse('2.19.1'),
      ],
    );
    await testCase.execute((command) async {
      await command.update();
      expect(
        testCase.printLog,
        contains('Successfully updated the Dart SDK to 2.19.1.'),
      );
      expect(testCase.downloadedDartSdkVersion, Version.parse('2.19.1'));
    });
  });

  test('UpdateCommand executes update script with downloaded Dart SDK',
      () async {
    final testCase = _UpdateCommandTestCase(
      initialSidekickCliVersion: Version.parse('1.1.0'),
      initialSidekickCoreVersion: Version.parse('1.1.0'),
      sidekickCoreReleases: [
        _sidekick_core('1.2.0', sdk: '>=2.12.0 <3.0.0'),
      ],
      dartSdks: [
        Version.parse('2.18.0'),
        Version.parse('2.19.1'),
      ],
    );
    await testCase.execute((command) async {
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
      await command.update();

      // Downloaded correct Dart version
      expect(testCase.downloadedDartSdkVersion, Version.parse('2.19.1'));

      // Correct arguments have been injected
      expect(testCase.printLog, contains('Arguments: [dash, 1.1.0, 1.2.0]'));

      // Update script has been executed with correct Dart SDK
      final fullLog = testCase.printLog.join('\n');
      expect(fullLog, contains('Downloading Dart SDK 2.19.1'));
      expect(fullLog, contains('Dart Version: 2.19.1'));
    });
  });

  test('Update to Dart 3 with sidekick 2.0', () async {
    final testCase = _UpdateCommandTestCase(
      initialSidekickCliVersion: Version.parse('1.2.0'),
      initialSidekickCoreVersion: Version.parse('1.2.0'),
      sidekickCoreReleases: [
        _sidekick_core('1.2.0', sdk: '>=2.12.0 <3.0.0'),
        _sidekick_core('2.0.0', sdk: '>=3.0.0 <3.999.0'),
      ],
      dartSdkVersion: Version.parse('2.19.6'),
      dartSdks: [
        Version.parse('2.18.0'),
        Version.parse('2.19.6'),
        Version.parse('3.0.0'),
        Version.parse('3.0.1'),
        Version.parse('4.0.0'),
      ],
    );
    await testCase.execute((command) async {
      _PrintOnlyUpdateExecutorTemplate.register();
      await command.update();

      // Dart SDK has been updated
      expect(testCase.downloadedDartSdkVersion, Version.parse('3.0.1'));

      // Correct arguments have been injected
      expect(testCase.printLog, contains('Arguments: [dash, 1.2.0, 2.0.0]'));

      // Update script has been executed with correct Dart SDK
      final fullLog = testCase.printLog.join('\n');
      expect(fullLog, contains('Downloading Dart SDK 3.0.1'));
      expect(fullLog, contains('Dart Version: 3.0.1'));
    });
  });

  test('Do not allow Dart 3.3 with sidekick 2.x', () async {
    final testCase = _UpdateCommandTestCase(
      initialSidekickCliVersion: Version.parse('2.2.0'),
      initialSidekickCoreVersion: Version.parse('2.2.0'),
      sidekickCoreReleases: [
        _sidekick_core('2.3.0', sdk: '>=3.0.0 <3.999.0'),
      ],
      dartSdkVersion: Version.parse('3.1.2'),
      dartSdks: [
        Version.parse('3.1.2'),
        Version.parse('3.2.6'),
        Version.parse('3.3.0'),
        Version.parse('3.4.0'),
      ],
    );
    await testCase.execute((command) async {
      _PrintOnlyUpdateExecutorTemplate.register();
      await command.update();

      // Dart SDK has been updated
      expect(testCase.downloadedDartSdkVersion, Version.parse('3.2.6'));

      // Correct arguments have been injected
      expect(testCase.printLog, contains('Arguments: [dash, 2.2.0, 2.3.0]'));

      final fullLog = testCase.printLog.join('\n');
      expect(fullLog, contains('Downloading Dart SDK 3.2.6'));
      expect(fullLog, contains('Dart Version: 3.2.6'));
    });
  });

  test('Use Dart >=3.3 with sidekick 3.x', () async {
    final testCase = _UpdateCommandTestCase(
      initialSidekickCliVersion: Version.parse('2.2.0'),
      initialSidekickCoreVersion: Version.parse('2.2.0'),
      sidekickCoreReleases: [
        _sidekick_core('2.3.0', sdk: '>=3.0.0 <3.999.0'),
        _sidekick_core('3.0.0', sdk: '>=3.3.0 <3.999.0'),
      ],
      dartSdkVersion: Version.parse('3.2.6'),
      dartSdks: [
        Version.parse('3.2.6'),
        Version.parse('3.3.4'),
        Version.parse('3.4.4'),
      ],
    );
    await testCase.execute((command) async {
      _PrintOnlyUpdateExecutorTemplate.register();
      await command.update();

      // Dart SDK has been updated
      expect(testCase.downloadedDartSdkVersion, Version.parse('3.4.4'));

      // Correct arguments have been injected
      expect(testCase.printLog, contains('Arguments: [dash, 2.2.0, 3.0.0]'));

      final fullLog = testCase.printLog.join('\n');
      expect(fullLog, contains('Downloading Dart SDK 3.4.4'));
      expect(fullLog, contains('Dart Version: 3.4.4'));
    });
  });

  test('Update to Dart 3.5 with sidekick 3.0.0-preview.5', () async {
    final testCase = _UpdateCommandTestCase(
      initialSidekickCliVersion: Version.parse('1.2.0'),
      initialSidekickCoreVersion: Version.parse('1.2.0'),
      sidekickCoreReleases: [
        _sidekick_core('1.2.0', sdk: '>=2.12.0 <3.0.0'),
        _sidekick_core('2.3.0', sdk: '>=3.0.0 <3.999.0'),
        _sidekick_core('3.0.0-preview.5', sdk: '>=3.5.0 <4.0.0'),
      ],
      dartSdkVersion: Version.parse('3.0.0'),
      dartSdks: [
        Version.parse('2.18.0'),
        Version.parse('2.19.6'),
        Version.parse('3.0.0'),
        Version.parse('3.0.1'),
        Version.parse('3.4.4'),
        Version.parse('3.5.0'),
        Version.parse('4.0.0'),
      ],
    );
    await testCase.execute((command) async {
      _PrintOnlyUpdateExecutorTemplate.register();
      await command.update(['3.0.0-preview.5']);

      // Dart SDK has been updated
      expect(testCase.downloadedDartSdkVersion, Version.parse('3.5.0'));

      // Correct arguments have been injected
      expect(
        testCase.printLog,
        contains('Arguments: [dash, 1.2.0, 3.0.0-preview.5]'),
      );

      // Update script has been executed with correct Dart SDK
      final fullLog = testCase.printLog.join('\n');
      expect(fullLog, contains('Downloading Dart SDK 3.5.0'));
      expect(fullLog, contains('Dart Version: 3.5.0'));
    });
  });

  test('Update with preview version when no compatible Dart SDKs are found',
      () async {
    final testCase = _UpdateCommandTestCase(
      initialSidekickCliVersion: Version.parse('1.2.0'),
      initialSidekickCoreVersion: Version.parse('1.2.0'),
      sidekickCoreReleases: [
        _sidekick_core('1.2.0', sdk: '>=2.12.0 <3.0.0'),
        _sidekick_core('3.0.0-preview.10', sdk: '>=3.6.0 <4.0.0'),
      ],
      dartSdkVersion: Version.parse('3.5.0'),
      dartSdks: [
        // No Dart SDKs that would be compatible with the preview version
        Version.parse('3.5.0'), // Current version - below 3.6.0 requirement
      ],
    );
    await testCase.execute((command) async {
      _PrintOnlyUpdateExecutorTemplate.register();
      await command.update(['3.0.0-preview.10']);

      // Should not crash and should handle the scenario gracefully
      // The update should use the current Dart SDK version with the preview version
      expect(testCase.downloadedDartSdkVersion, Version.parse('3.5.0'));

      // Should use the current Dart SDK version with the specified preview version
      expect(
        testCase.printLog,
        contains('Arguments: [dash, 1.2.0, 3.0.0-preview.10]'),
      );
    });
  });

  test(
      'Update with preview version prevents crash when availableDartVersions is empty',
      () async {
    final testCase = _UpdateCommandTestCase(
      initialSidekickCliVersion: Version.parse('1.2.0'),
      initialSidekickCoreVersion: Version.parse('1.2.0'),
      sidekickCoreReleases: [
        _sidekick_core('1.2.0', sdk: '>=2.12.0 <3.0.0'),
        // Preview version available but no compatible releases for future Dart SDKs
        _sidekick_core('3.0.0-preview.15', sdk: '>=3.7.0 <4.0.0'),
      ],
      dartSdkVersion: Version.parse('3.5.0'),
      dartSdks: [
        Version.parse('3.5.0'), // Current version
        Version.parse(
            '3.6.0'), // Available but not compatible with preview's >=3.7.0 requirement
      ],
    );
    await testCase.execute((command) async {
      _PrintOnlyUpdateExecutorTemplate.register();
      await command.update(['3.0.0-preview.15']);

      // The test verifies that the update doesn't crash even when:
      // 1. A preview version is requested
      // 2. No future Dart SDKs are compatible with the preview version requirements
      // 3. availableDartVersions would be empty without the fix

      // Should use the current Dart SDK version with the specified preview version
      expect(testCase.downloadedDartSdkVersion, Version.parse('3.5.0'));
      expect(
        testCase.printLog,
        contains('Arguments: [dash, 1.2.0, 3.0.0-preview.15]'),
      );
    });
  });

  test('Update from one preview version to another preview version', () async {
    final testCase = _UpdateCommandTestCase(
      initialSidekickCliVersion: Version.parse('3.0.0-preview.5'),
      initialSidekickCoreVersion: Version.parse('3.0.0-preview.5'),
      sidekickCoreReleases: [
        _sidekick_core('3.0.0-preview.5', sdk: '>=3.5.0 <4.0.0'),
        _sidekick_core('3.0.0-preview.6', sdk: '>=3.5.0 <4.0.0'),
      ],
      dartSdkVersion: Version.parse('3.5.0'),
      dartSdks: [
        Version.parse(
            '3.5.0'), // Current version, compatible with both preview versions
        Version.parse('3.5.1'), // Newer version, also compatible
      ],
    );
    await testCase.execute((command) async {
      _PrintOnlyUpdateExecutorTemplate.register();
      await command.update(['3.0.0-preview.6']);

      // Should successfully update from preview.5 to preview.6
      // When multiple compatible Dart versions are available, it chooses the latest (3.5.1)
      expect(testCase.downloadedDartSdkVersion, Version.parse('3.5.1'));
      expect(
        testCase.printLog,
        contains('Arguments: [dash, 3.0.0-preview.5, 3.0.0-preview.6]'),
      );

      // Should indicate the update is happening
      final fullLog = testCase.printLog.join('\n');
      expect(fullLog, contains('Updating sidekick from 3.0.0-preview.5'));
      expect(fullLog, contains('to 3.0.0-preview.6'));
    });
  });

  test(
      'should not suggest incompatible Dart versions when upgrading from 2.1.2 to 3.0.0-preview.6',
      () async {
    final testCase = _UpdateCommandTestCase(
      initialSidekickCliVersion: Version.parse('2.1.2'),
      initialSidekickCoreVersion: Version.parse('2.1.2'),
      sidekickCoreReleases: [
        _sidekick_core('2.1.2', sdk: '>=3.0.0 <3.3.0'),
        _sidekick_core('3.0.0-preview.6', sdk: '>=3.5.0 <4.0.0'),
      ],
      dartSdks: [
        Version.parse('3.2.6'), // Current Dart version - compatible with 2.1.2
        Version.parse(
            '3.3.0'), // Incompatible with 3.0.0-preview.6, compatible with 2.1.2
        Version.parse('3.4.0'), // Incompatible with any version
        Version.parse('3.5.0'), // Compatible with 3.0.0-preview.6 but not 2.1.2
        Version.parse('3.6.0'), // Compatible with 3.0.0-preview.6 but not 2.1.2
      ],
      dartSdkVersion: Version.parse('3.2.6'), // Starting with Dart 3.2.6
    );

    await testCase.execute((command) async {
      _PrintOnlyUpdateExecutorTemplate.register();
      await command.update(['3.0.0-preview.6']);

      // Should only offer compatible Dart SDKs for 3.0.0-preview.6 (3.5.0 and 3.6.0)
      // Should not offer Dart 3.3.X or 3.4.X since they would make the upgrade path incompatible
      // Should choose the latest compatible version (3.6.0)
      expect(testCase.downloadedDartSdkVersion, Version.parse('3.6.0'));

      final fullLog = testCase.printLog.join('\n');
      expect(fullLog, contains('Updating sidekick from 2.1.2'));
      expect(fullLog, contains('to 3.0.0-preview.6'));
      expect(fullLog, contains('Dart 3.6.0'));

      expect(fullLog, isNot(contains('to 3.0.0-preview.6 (Dart 3.3.0)')));
      expect(fullLog, isNot(contains('to 3.0.0-preview.6 (Dart 3.4.0)')));
    });
  });
}

// ignore: non_constant_identifier_names
_PublishedPackage _sidekick_core(
  String version, {
  required String sdk,
}) {
  return _PublishedPackage(
    name: 'sidekick_core',
    version: Version.parse(version),
    dartSdkConstraint: VersionConstraint.parse(sdk),
  );
}

class _PublishedPackage {
  final String name;
  final Version version;
  final VersionConstraint dartSdkConstraint;

  _PublishedPackage({
    required this.name,
    required this.version,
    required this.dartSdkConstraint,
  });
}

class _UpdateCommandTestCase {
  final Version? initialSidekickCliVersion;
  final Version? initialSidekickCoreVersion;

  final List<_PublishedPackage> sidekickCoreReleases;
  final List<Version> dartSdks;
  final Version? dartSdkVersion;

  _UpdateCommandTestCase({
    this.initialSidekickCliVersion,
    this.initialSidekickCoreVersion,
    required this.sidekickCoreReleases,
    List<Version>? dartSdks,
    this.dartSdkVersion,
  }) : dartSdks = dartSdks ?? [Version.parse('2.19.6')];

  final printLog = <String>[];
  final command = UpdateCommand();

  Directory get projectDir => _projectDir;
  late Directory _projectDir;

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

  Future<void> execute(
    Future<void> Function(_UpdateCommandUnderTest command) code,
  ) async {
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

          // Set up mock for the new compatibility check method
          VersionChecker.testFakeIsPackageVersionCompatibleWithDartSdk = ({
            required String dependency,
            required Version packageVersion,
            required Version dartSdkVersion,
          }) async {
            if (dependency == 'sidekick_core') {
              final package = sidekickCoreReleases
                  .where((package) => package.version == packageVersion)
                  .firstOrNull;
              if (package != null) {
                return package.dartSdkConstraint.allows(dartSdkVersion);
              }
            }
            return false;
          };
          addTearDown(
            () => VersionChecker.testFakeIsPackageVersionCompatibleWithDartSdk =
                null,
          );

          _LocalUpdateExecutorTemplate.register();

        final sdk = dartSdkVersion ?? dartSdks.first;

        await insideFakeProjectWithSidekick(
          (dir) async {
            _projectDir = dir;
            await code(_UpdateCommandUnderTest(this));
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

class _UpdateCommandUnderTest {
  _UpdateCommandUnderTest(this.testCase);

  final _UpdateCommandTestCase testCase;

  /// Calls the [UpdateCommand] with the given [args]
  Future<void> update([List<String> args = const []]) async {
    final runner = initializeSidekick(dartSdkPath: systemDartSdkPath());

    final archive = _MockDartArchive();
    archive.versions.addAll(testCase.dartSdks);
    runner.addCommand(testCase.command..dartArchive = archive);

    await runner.run(['update', ...args]);
  }
}

class _MockDartArchive implements DartArchive {
  final List<Version> versions = [];

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

  static void register() {
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
      return UpdateExecutorTemplate.testFakeCreateUpdateExecutorTemplate = null;
    });
  }

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

/// Writes the normal [UpdateExecutorTemplate] but links the local sidekick_core package
class _LocalUpdateExecutorTemplate extends UpdateExecutorTemplate {
  _LocalUpdateExecutorTemplate({
    required super.location,
    required super.dartSdkVersion,
    required super.oldSidekickCoreVersion,
    required super.newSidekickCoreVersion,
  }) : super.raw();

  static void register() {
    UpdateExecutorTemplate.testFakeCreateUpdateExecutorTemplate = ({
      required Directory location,
      required Version dartSdkVersion,
      required Version newSidekickCoreVersion,
      required Version oldSidekickCoreVersion,
    }) {
      return _LocalUpdateExecutorTemplate(
        location: location,
        dartSdkVersion: dartSdkVersion,
        newSidekickCoreVersion: newSidekickCoreVersion,
        oldSidekickCoreVersion: oldSidekickCoreVersion,
      );
    };
    addTearDown(() {
      return UpdateExecutorTemplate.testFakeCreateUpdateExecutorTemplate = null;
    });
  }

  @override
  void generate() {
    super.generate();
    overrideSidekickCoreWithLocalPath(location);
  }
}
