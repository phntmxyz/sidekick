import 'package:sidekick_core/sidekick_core.dart' hide withEnvironment;
import 'package:sidekick_test/sidekick_test.dart';
import 'package:sidekick_vault/sidekick_vault.dart';
import 'package:test/test.dart';

// withEnvironment doesn't support async callbacks. core does. Fixed in dcli:2.0.0-beta.14
// ignore: directives_ordering, depend_on_referenced_packages
import 'package:dcli_core/dcli_core.dart' show withEnvironment;

void main() {
  late CommandRunner runner;
  late SidekickVault vault;
  setUp(() async {
    await insideFakeProjectWithSidekick((projectRoot) async {
      final tempVault = Directory.systemTemp.createTempSync();
      await Directory('test/vault').copyRecursively(tempVault);
      vault = SidekickVault(
        location: tempVault,
        environmentVariableName: 'DASH_VAULT_PASSPHRASE',
      );
      runner = initializeSidekick();
      runner.addCommand(VaultCommand(vault: vault));
    });
  });

  test('encrypt/decrypt a file', () async {
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
    await withEnvironment(
      () async {
        await runner.run([
          'vault',
          'encrypt',
          '--passphrase',
          'dartlang',
          '--vault-location',
          'secret.txt.gpg',
          clearTextFile.absolute.path,
        ]);

        await runner.run([
          'vault',
          'decrypt',
          '--passphrase',
          'dartlang',
          '--output',
          decryptedFile.absolute.path,
          'secret.txt.gpg',
        ]);
      },
      environment: {
        'DASH_VAULT_PASSPHRASE': 'asdfasdf',
        'SIDEKICK_ENABLE_UPDATE_CHECK': 'false',
      },
    );
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
                contains('dash vault decrypt secret.txt.gpg'),
              ),
        ),
      );
    });
    test('throws for non-files', () {
      expect(
        () => withEnvironment(
          () => runner.run(['vault', 'decrypt', 'unknown.gpg']),
          environment: {
            'DASH_VAULT_PASSPHRASE': 'asdfasdf',
            'SIDEKICK_ENABLE_UPDATE_CHECK': 'false',
          },
        ),
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
                contains('dash vault decrypt secret.txt.gpg'),
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
                contains('dash vault encrypt secret.txt'),
              ),
        ),
      );
    });
    test('throws for non-files (absolute path)', () {
      expect(
        () => withEnvironment(
          () => runner.run(['vault', 'encrypt', 'unknown.gpg']),
          environment: {
            'DASH_VAULT_PASSPHRASE': 'asdfasdf',
            'SIDEKICK_ENABLE_UPDATE_CHECK': 'false',
          },
        ),
        throwsA(
          isA<String>().having(
            (it) => it,
            'error',
            contains('unknown.gpg does not exist in'),
          ),
        ),
      );
    });
    test('throws for non-files (relative path)', () {
      expect(
        () => withEnvironment(
          () => runner.run(['vault', 'encrypt', '/root/unknown.gpg']),
          environment: {
            'DASH_VAULT_PASSPHRASE': 'asdfasdf',
            'SIDEKICK_ENABLE_UPDATE_CHECK': 'false',
          },
        ),
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
                contains('dash vault encrypt secret.txt.gpg'),
              ),
        ),
      );
    });
  });

  test('Change password', () async {
    await runner.run([
      'vault',
      'change-password',
      '--old',
      'asdfasdf',
      '--new',
      'newpw',
    ]);

    final tempDir = Directory.systemTemp.createTempSync();
    addTearDown(() {
      tempDir.deleteSync(recursive: true);
    });
    final decryptedFile = tempDir.file('decrypted.txt');
    await runner.run([
      'vault',
      'decrypt',
      '--passphrase',
      'newpw',
      '--output',
      decryptedFile.absolute.path,
      'encrypted.txt.gpg',
    ]);

    expect(decryptedFile.readAsStringSync(), '42');
  });

  test('encrypt overwrites existing files', () async {
    final tempDir = Directory.systemTemp.createTempSync();
    final clearTextFile = tempDir.file('cleartext.txt')
      ..writeAsStringSync('Dash is cool');
    addTearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    await withEnvironment(
      () async {
        await runner.run([
          'vault',
          'encrypt',
          '--passphrase',
          'dartlang',
          '--vault-location',
          'secret.txt.gpg',
          clearTextFile.absolute.path,
        ]);

        // writing it a second time works just fine
        await runner.run([
          'vault',
          'encrypt',
          '--passphrase',
          'dartlang',
          '--vault-location',
          'secret.txt.gpg',
          clearTextFile.absolute.path,
        ]);
      },
      environment: {
        'DASH_VAULT_PASSPHRASE': 'asdfasdf',
        'SIDEKICK_ENABLE_UPDATE_CHECK': 'false',
      },
    );
  });
}
