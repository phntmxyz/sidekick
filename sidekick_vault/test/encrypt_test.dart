import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_vault/sidekick_vault.dart';
import 'package:test/test.dart';

void main() {
  group('encrypt:', () {
    setUp(() {
      initializeSidekick(name: 'flg');
      addTearDown(() {
        deinitializeSidekick();
      });
    });
    test('no file', () {
      final runner = CommandRunner('', '')..addCommand(VaultCommand());
      expect(
        () => runner.run(['vault', 'encrypt']),
        throwsA(
          isA<String>()
              .having(
                (it) => it,
                'error',
                contains('Missing file'),
              )
              .having(
                (it) => it,
                'example',
                contains('flg vault encrypt file.csv'),
              ),
        ),
      );
    });
    test('not a file', () {
      final runner = CommandRunner('', '')..addCommand(VaultCommand());
      expect(
        () => runner.run(['vault', 'encrypt', '.']),
        throwsA(
          isA<String>()
              .having(
                (it) => it,
                'error',
                contains('No valid file'),
              )
              .having(
                (it) => it,
                'example',
                contains('flg vault encrypt file.csv'),
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
          isA<String>()
              .having(
                (it) => it,
                'error',
                contains('Enter one file only'),
              )
              .having(
                (it) => it,
                'example',
                contains('flg vault encrypt file.csv'),
              ),
        ),
      );
    });
  });
}
