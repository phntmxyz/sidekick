import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_vault/sidekick_vault.dart';
import 'package:test/test.dart';

void main() {
  group('decrypt:', () {
    test('no file', () {
      final runner = CommandRunner('', '')..addCommand(VaultCommand());
      expect(
        () => runner.run(['vault', 'decrypt']),
        throwsA(isA<String>()),
      );
    });
    test('not a file', () {
      final runner = CommandRunner('', '')..addCommand(VaultCommand());
      expect(
        () => runner.run(['vault', 'decrypt', '.']),
        throwsA(isA<String>()),
      );
    });
    test('more than one file', () {
      final runner = CommandRunner('', '')..addCommand(VaultCommand());
      expect(
        () => runner.run(['vault', 'decrypt', 'test/vault/encrypted.txt.gpg', 'test/vault/encrypted.txt.gpg']),
        throwsA(isA<String>()),
      );
    });
  });
}
