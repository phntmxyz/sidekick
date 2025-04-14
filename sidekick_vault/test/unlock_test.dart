import 'package:dcli_core/dcli_core.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_vault/sidekick_vault.dart';
import 'package:test/test.dart';

// ignore_for_file: unnecessary_async
void main() {
  test('unlock with env', () async {
    await withEnvironment(
      () async {
        final vault = SidekickVault(
          location: Directory('test/vault'),
          environmentVariableName: 'VAULT_PASSPHRASE',
        );
        expect(vault.loadText('encrypted.txt.gpg'), '42');
      },
      environment: {'VAULT_PASSPHRASE': 'asdfasdf'},
    );
  });

  test('wrong passphrase errors', () async {
    await withEnvironment(
      () async {
        final vault = SidekickVault(
          location: Directory('test/vault'),
          environmentVariableName: 'VAULT_PASSPHRASE',
        );
        expect(
          () => vault.loadText('encrypted.txt.gpg'),
          throwsA(
            isA<RunException>()
                .having(
                  (it) => it.toString(),
                  'error',
                  allOf([contains('gpg'), contains('encrypted.txt')]),
                )
                .having((it) => it.exitCode, 'exitCode', 2),
          ),
        );
        // Also prints "gpg: decryption failed: Bad session key" to console
      },
      environment: {'VAULT_PASSPHRASE': 'wrong'},
    );
  });

  test('No env errors on CI', () async {
    await withEnvironment(
      () async {
        final vault = SidekickVault(
          location: Directory('test/vault'),
          environmentVariableName: 'VAULT_PASSPHRASE',
        );
        expect(
          () => vault.loadText('encrypted.txt.gpg'),
          throwsA(
            isA<String>().having(
              (it) => it,
              'error',
              'Password in env.VAULT_PASSPHRASE is not defined and user input was empty',
            ),
          ),
        );
      },
      environment: {},
    );
  });
}
