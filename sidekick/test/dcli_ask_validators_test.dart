import 'package:sidekick/src/util/dcli_ask_validators.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:test/test.dart';

void main() {
  group('CliNameValidator', () {
    final validate = const CliNameValidator().validate;

    test('returns cli name when it is valid', () {
      expect(validate('dashi_42'), 'dashi_42');
    });

    test('throws AskValidatorException when cli name is invalid', () {
      expect(() => validate('42'), throwsA(isA<AskValidatorException>()));
    });
  });

  group('DirectoryExistsValidator', () {
    final validate = const DirectoryExistsValidator().validate;

    test('returns path when directory exists (absolute path)', () {
      expect(validate(Directory.current.path), Directory.current.path);
    });

    test('returns path when directory exists (relative path)', () {
      final temp = Directory.systemTemp.createTempSync();
      addTearDown(() => temp.deleteSync(recursive: true));
      temp.directory('foo').createSync();

      expect(DirectoryExistsValidator(temp).validate('foo'), 'foo');
    });

    test('throws AskValidatorException when directory does not exist', () {
      final tempDir = Directory.systemTemp.createTempSync();
      tempDir.deleteSync();
      expect(
        () => validate(tempDir.path),
        throwsA(isA<AskValidatorException>()),
      );
    });
  });

  group('DirectoryIsWithinOrEqualValidator', () {
    test('returns path when directory is inside', () {
      final temp = Directory.systemTemp.createTempSync();
      addTearDown(() => temp.deleteSync(recursive: true));
      temp.directory('foo').createSync();

      final validate = DirectoryIsWithinOrEqualValidator(temp).validate;

      expect(validate('foo'), 'foo');
    });

    test('throws AskValidatorException when directory is not inside', () {
      final temp = Directory.systemTemp.createTempSync();
      addTearDown(() => temp.deleteSync());
      final validate = DirectoryIsWithinOrEqualValidator(temp).validate;

      expect(
        () => validate(Directory.current.path),
        throwsA(isA<AskValidatorException>()),
      );
    });
  });
}
