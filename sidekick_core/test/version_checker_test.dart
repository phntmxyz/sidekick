import 'package:pubspec2/pubspec2.dart' hide PubSpec;
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/version_checker.dart';
import 'package:test/test.dart';

void main() {
  late File pubspecFile;
  late VersionChecker versionChecker;

  setUp(() {
    final temp = Directory.systemTemp.createTempSync();
    pubspecFile = temp.file('pubspec.yaml')..writeAsStringSync('name: dashi');
    env['SIDEKICK_PACKAGE_HOME'] = temp.path;
    versionChecker = VersionChecker(DartPackage.fromDirectory(temp)!);

    addTearDown(() {
      env['SIDEKICK_PACKAGE_HOME'] = null;
      temp.deleteSync(recursive: true);
    });
  });

  group('updateVersionConstraint', () {
    test('updates package when it already exists in pubspec', () async {
      pubspecFile.writeAsStringSync('''
name: dashi
dependencies:
  foo: 1.2.3
''');

      final newVersion = Version(1, 2, 4);

      versionChecker.updateVersionConstraint(
        pubspecKeys: ['dependencies', 'foo'],
        newMinimumVersion: newVersion,
        pinVersion: true,
      );

      final pubspec = PubSpec.fromFile(pubspecFile.path);
      expect(
        pubspec.dependencies['foo']?.reference,
        isA<HostedReference>().having(
          (p0) => p0.versionConstraint,
          'versionConstraint',
          Version(1, 2, 4),
        ),
      );
      expect(
        pubspecFile.readAsStringSync(),
        '''
name: dashi
dependencies:
  foo: 1.2.4
''',
      );
    });

    test('sets package when it does not yet exist in pubspec', () async {
      // foo does not exist in the pubspec yet, it should be added by updateVersionConstraint
      pubspecFile.writeAsStringSync('''
name: dashi
dependencies:
  bar: 0.0.0
''');

      final newVersion = Version(1, 2, 4);

      versionChecker.updateVersionConstraint(
        pubspecKeys: ['dependencies', 'foo'],
        newMinimumVersion: newVersion,
        pinVersion: true,
      );

      final pubspec = PubSpec.fromFile(pubspecFile.path);
      expect(
        pubspec.dependencies['foo']?.reference,
        isA<HostedReference>().having(
          (p0) => p0.versionConstraint,
          'versionConstraint',
          Version(1, 2, 4),
        ),
      );
      expect(
        pubspecFile.readAsStringSync(),
        '''
name: dashi
dependencies:
  foo: 1.2.4
  bar: 0.0.0
''',
      );
    });
    test('sets whole block when it does not yet exist in pubspec', () async {
      pubspecFile.writeAsStringSync('''
name: dashi
# the pubspec does not have a dependencies block, it should be added by updateVersionConstraint
''');
      final newVersion = Version(1, 2, 4);

      versionChecker.updateVersionConstraint(
        pubspecKeys: ['dependencies', 'foo'],
        newMinimumVersion: newVersion,
        pinVersion: true,
      );

      final pubspec = PubSpec.fromFile(pubspecFile.path);
      expect(
        pubspec.dependencies['foo']?.reference,
        isA<HostedReference>().having(
          (p0) => p0.versionConstraint,
          'versionConstraint',
          Version(1, 2, 4),
        ),
      );
      expect(
        pubspecFile.readAsStringSync(),
        '''
name: dashi
# the pubspec does not have a dependencies block, it should be added by updateVersionConstraint
dependencies:
  foo: 1.2.4
''',
      );
    });
  });
}
