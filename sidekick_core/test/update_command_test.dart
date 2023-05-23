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
