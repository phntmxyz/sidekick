import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/version_checker.dart';
import 'package:sidekick_test/sidekick_test.dart';
import 'package:test/test.dart';

void main() {
  late File pubspecYamlFile;
  late File pubspecLockFile;
  late DartPackage package;

  setUp(() {
    final temp = Directory.systemTemp.createTempSync();
    pubspecYamlFile = temp.file('pubspec.yaml')
      ..writeAsStringSync('name: dashi');
    pubspecLockFile = temp.file('pubspec.lock');
    env['SIDEKICK_PACKAGE_HOME'] = temp.path;
    package = DartPackage.fromDirectory(temp)!;

    addTearDown(() {
      env['SIDEKICK_PACKAGE_HOME'] = null;
      temp.deleteSync(recursive: true);
    });
  });

  group('updateVersionConstraint', () {
    test('updates package when it already exists in pubspec', () async {
      pubspecYamlFile.writeAsStringSync('''
name: dashi
dependencies:
  foo: 1.2.3
''');

      VersionChecker.updateVersionConstraint(
        package: package,
        pubspecKeys: ['dependencies', 'foo'],
        newMinimumVersion: Version(1, 2, 4),
        pinVersion: true,
      );

      expect(
        pubspecYamlFile.readAsStringSync(),
        '''
name: dashi
dependencies:
  foo: 1.2.4
''',
      );
    });

    test('sets package when it does not yet exist in pubspec', () async {
      // foo does not exist in the pubspec yet, it should be added by updateVersionConstraint
      pubspecYamlFile.writeAsStringSync('''
name: dashi
dependencies:
  bar: 0.0.0
''');

      VersionChecker.updateVersionConstraint(
        package: package,
        pubspecKeys: ['dependencies', 'foo'],
        newMinimumVersion: Version(1, 2, 4),
        pinVersion: true,
      );

      expect(
        pubspecYamlFile.readAsStringSync(),
        '''
name: dashi
dependencies: 
  bar: 0.0.0
  foo: 1.2.4
''',
      );
    });
    test('sets whole block when it does not yet exist in pubspec', () async {
      pubspecYamlFile.writeAsStringSync('''
name: dashi
# the pubspec does not have a dependencies block, it should be added by updateVersionConstraint''');

      VersionChecker.updateVersionConstraint(
        package: package,
        pubspecKeys: ['dependencies', 'foo'],
        newMinimumVersion: Version(1, 2, 4),
        pinVersion: true,
      );

      expect(
        pubspecYamlFile.readAsStringSync(),
        '''
name: dashi
dependencies:
  foo: 1.2.4
# the pubspec does not have a dependencies block, it should be added by updateVersionConstraint
''',
      );
    });

    test('replace path dependency with pub version', () async {
      pubspecYamlFile.writeAsStringSync('''
name: dashi
dependencies:
  sidekick_core:
    path: ../sidekick_core
''');

      VersionChecker.updateVersionConstraint(
        package: package,
        pubspecKeys: ['dependencies', 'sidekick_core'],
        newMinimumVersion: Version(0, 14, 0),
        pinVersion: true,
      );

      expect(
        pubspecYamlFile.readAsStringSync(),
        '''
name: dashi
dependencies:
  sidekick_core: 0.14.0
''',
      );
    });

    test('replace git dependency with pub version', () async {
      pubspecYamlFile.writeAsStringSync('''
name: dashi
dependencies:
  some_sidekick_plugin:
    git:
      url: git@github.com:phntmxyz/some_sidekick_plugin.git
      ref: main
''');

      VersionChecker.updateVersionConstraint(
        package: package,
        pubspecKeys: ['dependencies', 'some_sidekick_plugin'],
        newMinimumVersion: Version(0, 14, 0),
        pinVersion: true,
      );

      expect(
        pubspecYamlFile.readAsStringSync(),
        '''
name: dashi
dependencies:
  some_sidekick_plugin: 0.14.0
''',
      );
    });
  });

  group('VersionChecker.getMinimumVersionConstraint', () {
    group('throws when ', () {
      test('path is empty', () {
        expect(
          () => VersionChecker.getMinimumVersionConstraint(package, []),
          throwsA("Need at least one key in path parameter, but it was empty."),
        );
      });

      test('yaml file does not exist', () {
        pubspecYamlFile.deleteSync();
        expect(
          () => VersionChecker.getMinimumVersionConstraint(
            package,
            ['dependencies', 'foo'],
          ),
          throwsA(
            "Tried reading '['dependencies', 'foo']' from yaml file '${pubspecYamlFile.path}', but that file doesn't exist.",
          ),
        );
      });
    });

    group('returns null when', () {
      test('path does not exist at all', () {
        pubspecYamlFile.writeAsStringSync('''
name: dashi
''');
        expect(
          VersionChecker.getMinimumVersionConstraint(
            package,
            ['dependencies', 'foo'],
          ),
          isNull,
        );
      });

      test('path exists only partially', () {
        pubspecYamlFile.writeAsStringSync('''
name: dashi
dependencies:
''');
        expect(
          VersionChecker.getMinimumVersionConstraint(
            package,
            ['dependencies', 'foo'],
          ),
          isNull,
        );
      });
    });

    test('returns Version.none when any version is allowed explicitly', () {
      pubspecYamlFile.writeAsStringSync('''
name: dashi

dependencies:
  foo: any
''');

      final actual = VersionChecker.getMinimumVersionConstraint(package, [
        'dependencies',
        'foo',
      ]);
      expect(actual, Version.none);
    });

    test('returns Version.none when any version is allowed implicitly', () {
      pubspecYamlFile.writeAsStringSync('''
name: dashi

dependencies:
  foo: 
''');

      final actual = VersionChecker.getMinimumVersionConstraint(
        package,
        ['dependencies', 'foo'],
      );
      expect(actual, Version.none);
    });

    test('returns correct version from normal range', () {
      pubspecYamlFile.writeAsStringSync('''
name: dashi

dependencies: 
  foo: '>=0.5.0 <1.0.0'
''');

      final actual = VersionChecker.getMinimumVersionConstraint(
        package,
        ['dependencies', 'foo'],
      );
      expect(actual, Version(0, 5, 0));
    });

    test('returns correct version if range order is unusual', () {
      pubspecYamlFile.writeAsStringSync('''
name: dashi

dependencies:
  foo: '<1.0.0 >=0.5.0'
''');

      final actual = VersionChecker.getMinimumVersionConstraint(
        package,
        ['dependencies', 'foo'],
      );
      expect(actual, Version(0, 5, 0));
    });

    test('returns correct version if range is exclusive on the lower end', () {
      pubspecYamlFile.writeAsStringSync('''
name: dashi

dependencies:
  foo: '>0.5.0 <1.0.0'
''');

      final actual = VersionChecker.getMinimumVersionConstraint(
        package,
        ['dependencies', 'foo'],
      );
      expect(actual, Version(0, 5, 1));
    });
  });

  group('getResolvedVersion', () {
    test('returns version from pubspec.lock', () {
      pubspecLockFile.writeAsStringSync('''
packages:
  foo:
    dependency: transitive
    description:
      name: foo
      url: "https://pub.dartlang.org"
    source: hosted
    version: "42.0.0"
''');

      final actual = VersionChecker.getResolvedVersion(package, 'foo');
      expect(actual, Version(42, 0, 0));
    });
  });

  group('getDartVersion', () {
    test('parses version and channel from version info string', () {
      const versionInfostring =
          'Dart SDK version: 2.18.4 (stable) (Tue Nov 1 15:15:07 2022 +0000) on "macos_arm64"';
      final fakeDart = fakePrintingDartSdk(versionInfostring).file('bin/dart');

      final expected =
          SdkVersion(version: Version(2, 18, 4), channel: 'stable');
      final actual = VersionChecker.getDartVersion(fakeDart.path);
      expect(actual, expected);
    });

    test('does not crash with real Dart SDK', () {
      expect(
        () => VersionChecker.getDartVersion(systemDartExecutable()!),
        returnsNormally,
      );
    });
  });
}
