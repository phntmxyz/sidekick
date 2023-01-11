import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';

void main() {
  group('isValidPubPackageName', () {
    test('valid examples', () {
      expect(isValidPubPackageName('what_a_week_huh'), isTrue);
      expect(isValidPubPackageName('captain'), isTrue);
      expect(isValidPubPackageName('it_s_wednesday'), isTrue);
    });
    test('leading _ is fine', () {
      expect(isValidPubPackageName('_captain'), isTrue);
    });
    test('numbers are allowed', () {
      expect(isValidPubPackageName('a38'), isTrue);
      // but not at the start
      expect(isValidPubPackageName('38'), isFalse);
    });
    test('keywords are invalid', () {
      expect(isValidPubPackageName('extension'), isFalse);
      expect(isValidPubPackageName('function'), isFalse);
    });
    test('no uppercase', () {
      expect(isValidPubPackageName('DASH'), isFalse);
    });
    test('no leading number', () {
      expect(isValidPubPackageName('3cool'), isFalse);
    });
    test('no dash', () {
      expect(isValidPubPackageName('no-dash'), isFalse);
    });
  });

  group('DartPackage.fromDirectory', () {
    test('detect dart package', () {
      final tempDir = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDir.deleteSync(recursive: true));
      tempDir.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync('''
name: package_name

''');

      final package = DartPackage.fromDirectory(tempDir);
      expect(package, isNotNull);
      expect(package!.name, 'package_name');
      expect(package.isFlutterPackage, isFalse);
    });

    test('detect minimal flutter package', () {
      final tempDir = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDir.deleteSync(recursive: true));
      tempDir.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync('''
name: package_name

dependencies:
  flutter:
''');

      final package = DartPackage.fromDirectory(tempDir);
      expect(package, isNotNull);
      expect(package!.name, 'package_name');
      expect(package.isFlutterPackage, isTrue);
    });

    test('detect usually looking flutter package', () {
      final tempDir = Directory.systemTemp.createTempSync();
      addTearDown(() => tempDir.deleteSync(recursive: true));
      tempDir.file('pubspec.yaml')
        ..createSync()
        ..writeAsStringSync('''
name: package_name

dependencies:
  flutter:
    sdk: flutter

flutter:
  uses-material-design: true
''');

      final package = DartPackage.fromDirectory(tempDir);
      expect(package, isNotNull);
      expect(package!.name, 'package_name');
      expect(package.isFlutterPackage, isTrue);
    });
  });
}
