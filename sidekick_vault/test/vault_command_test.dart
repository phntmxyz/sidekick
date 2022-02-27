import 'dart:async';

import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_vault/sidekick_vault.dart';
import 'package:test/test.dart';

void main() {
  late CommandRunner runner;
  setUp(() {
    initializeSidekick(name: 'flg');
    addTearDown(() {
      deinitializeSidekick();
    });

    runner = CommandRunner('', '')..addCommand(VaultCommand());
  });

  test('encrypt/decrypt a file', () {
    final tempDir = Directory.systemTemp.createTempSync();
    final clearTextFile = tempDir.file('cleartext.txt')
      ..writeAsStringSync('Dash is cool');
    addTearDown(() {
      clearTextFile.deleteSync();
    });
    final encryptedFile = tempDir.file('encrypted.gpg.txt');

    runner.run([
      'vault',
      'encrypt',
      '--passphrase',
      'dartlang',
      '--output',
      encryptedFile.absolute.path,
      clearTextFile.absolute.path,
    ]);

    expect(encryptedFile.existsSync(), isTrue);

    final decryptedFile = tempDir.file('decrypted.txt');
    runner.run([
      'vault',
      'decrypt',
      '--passphrase',
      'dartlang',
      '--output',
      decryptedFile.absolute.path,
      encryptedFile.absolute.path,
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
                contains('flg vault decrypt file.csv.gpg'),
              ),
        ),
      );
    });
    test('throws for non-files', () {
      expect(
        () => runner.run(['vault', 'decrypt', '.']),
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
                contains('flg vault decrypt file.csv.gpg'),
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
                contains('flg vault decrypt file.csv.gpg'),
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
                contains('flg vault encrypt file.csv'),
              ),
        ),
      );
    });
    test('throws for non-files', () {
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
                contains('flg vault encrypt file.csv'),
              ),
        ),
      );
    });
  });
}
