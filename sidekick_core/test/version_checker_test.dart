import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/version_checker.dart';
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
  foo: 1.2.4
  bar: 0.0.0
''',
      );
    });
    test('sets whole block when it does not yet exist in pubspec', () async {
      pubspecYamlFile.writeAsStringSync('''
name: dashi
# the pubspec does not have a dependencies block, it should be added by updateVersionConstraint
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
# the pubspec does not have a dependencies block, it should be added by updateVersionConstraint
dependencies:
  foo: 1.2.4
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
}
