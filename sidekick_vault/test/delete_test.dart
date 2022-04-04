import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_vault/sidekick_vault.dart';
import 'package:test/test.dart';

void main() {
  test('delete entry from vault - without passphrase', () {
    final vaultDir = Directory.systemTemp.createTempSync();
    final tempFile = vaultDir.file('test.txt');
    tempFile.writeAsStringSync('clear text');

    // save file with passphrase
    withEnvironment(
      () {
        final vault = SidekickVault(
          location: vaultDir,
          environmentVariableName: 'VAULT_PASSPHRASE',
        );
        vault.saveFile(tempFile, filename: 'test.txt.gpg');
        expect(vaultDir.file('test.txt.gpg').existsSync(), isTrue);
      },
      environment: {'VAULT_PASSPHRASE': 'asdfasdf'},
    );

    // delete without passphrase

    final vault = SidekickVault(
      location: vaultDir,
      environmentVariableName: 'VAULT_PASSPHRASE',
    );
    vault.deleteFile('test.txt.gpg');
    expect(vaultDir.file('test.txt.gpg').existsSync(), isFalse);
  });

  test('clears cache after delete', () {
    withEnvironment(
      () {
        final vaultDir = Directory.systemTemp.createTempSync();
        final tempFile = vaultDir.file('test.txt');
        tempFile.writeAsStringSync('clear text');
        final vault = SidekickVault(
          location: vaultDir,
          environmentVariableName: 'VAULT_PASSPHRASE',
        );
        vault.saveFile(tempFile, filename: 'test.txt.gpg');
        expect(vaultDir.file('test.txt.gpg').existsSync(), isTrue);

        // now in cache
        expect(vault.loadText('test.txt.gpg'), 'clear text');

        vault.deleteFile('test.txt.gpg');
        expect(vaultDir.file('test.txt.gpg').existsSync(), isFalse);

        // removed from cache
        expect(
          () => vault.loadText('test.txt.gpg'),
          throwsA(
            isA<String>().having(
              (it) => it,
              'text',
              contains('test.txt.gpg does not exist in vault'),
            ),
          ),
        );
      },
      environment: {'VAULT_PASSPHRASE': 'asdfasdf'},
    );
  });
}
