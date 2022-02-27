import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_vault/sidekick_vault.dart';
import 'package:test/test.dart';

void main() {
  late CommandRunner runner;
  setUp(() {
    Env.mock = Env.forScope({'FLG_VAULT_PASSPHRASE': 'asdfasdf'});
    initializeSidekick(name: 'flg');
    addTearDown(() {
      deinitializeSidekick();
    });

    final vault = SidekickVault(
      location: Directory('test/vault'),
      environmentVariableName: 'FLG_VAULT_PASSPHRASE',
    );

    runner = CommandRunner('', '')..addCommand(VaultCommand(vault: vault));
  });

  test('encrypt/decrypt a file', () {
    final secretFile = File('test/vault/secret.txt.gpg');
    final tempDir = Directory.systemTemp.createTempSync();

    final clearTextFile = tempDir.file('cleartext.txt')
      ..writeAsStringSync('Dash is cool');
    addTearDown(() {
      if (secretFile.existsSync()) {
        secretFile.deleteSync();
      }
      tempDir.deleteSync(recursive: true);
    });
    final decryptedFile = tempDir.file('decrypted.txt');
    runner.run([
      'vault',
      'encrypt',
      '--passphrase',
      'dartlang',
      '--vault-location',
      'secret.txt.gpg',
      clearTextFile.absolute.path,
    ]);

    runner.run([
      'vault',
      'decrypt',
      '--passphrase',
      'dartlang',
      '--output',
      decryptedFile.absolute.path,
      'secret.txt.gpg',
    ]);
    expect(decryptedFile.readAsStringSync(), 'Dash is cool');
  });

  group('decrypt args validation', () {
    test('throws without file', () {
      expect(
        () => runner.run(['vault', 'decrypt']),
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
                contains('flg vault decrypt secret.txt.gpg'),
              ),
        ),
      );
    });
    test('throws for non-files', () {
      expect(
        () => runner.run(['vault', 'decrypt', 'unknown.gpg']),
        throwsA(
          isA<String>().having(
            (it) => it,
            'error',
            contains('unknown.gpg does not exist in vault'),
          ),
        ),
      );
    });
    test('throws for multiple files', () {
      expect(
        () => runner.run([
          'vault',
          'decrypt',
          'test/vault/encrypted.txt.gpg',
          'test/vault/encrypted.txt.gpg',
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
                contains('flg vault decrypt secret.txt.gpg'),
              ),
        ),
      );
    });
  });
  group('encrypt args validation', () {
    test('throws without file', () {
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
                contains('flg vault encrypt secret.txt'),
              ),
        ),
      );
    });
    test('throws for non-files', () {
      expect(
        () => runner.run(['vault', 'encrypt', 'unknown.gpg']),
        throwsA(
          isA<String>().having(
            (it) => it,
            'error',
            contains('unknown.gpg does not exist'),
          ),
        ),
      );
    });
    test('throws for multiple files', () {
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
                contains('flg vault encrypt secret.txt.gpg'),
              ),
        ),
      );
    });
  });
}
