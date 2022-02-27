import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_vault/sidekick_vault.dart';
import 'package:test/test.dart';

void main() {
  group('encrypt:', () {
    test('no file', () {
      final runner = CommandRunner('', '')..addCommand(VaultCommand());
      expect(
        () => runner.run(['vault', 'encrypt']),
        throwsA(
          isA<String>().having(
            (it) => it,
            'error',
            'Missing file'
                '\n'
                'Example:\n'
                'flg vault encrypt file.csv',
          ),
        ),
      );
    });
    test('not a file', () {
      final runner = CommandRunner('', '')..addCommand(VaultCommand());
      expect(
        () => runner.run(['vault', 'encrypt', '.']),
        throwsA(
          isA<String>().having(
            (it) => it,
            'error',
            'No valid file'
                '\n'
                'Example:\n'
                'flg vault encrypt file.csv',
          ),
        ),
      );
    });
    test('more than one file', () {
      final runner = CommandRunner('', '')..addCommand(VaultCommand());
      expect(
        () => runner.run([
          'vault',
          'encrypt',
          'test/vault/decrypted.txt',
          'test/vault/decrypted.txt',
        ]),
        throwsA(
          isA<String>().having(
            (it) => it,
            'error',
            'Enter one file only'
                '\n'
                'Example:\n'
                'flg vault encrypt file.csv',
          ),
        ),
      );
    });
  });
}
