import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_vault/sidekick_vault.dart';

void main() {
  final vault = SidekickVault(
    location: SidekickContext.projectRoot.directory('vault'),
    // environment variable where CIs can inject the vault password
    environmentVariableName: 'FLT_VAULT_PASSPHRASE',
  );

// define encrypted files in vault
  final EncryptedVaultString encrypted = vault.encryptedString('secret.txt');
// access the text prompts the passsword
  print(encrypted.text);

  // directly decrypt (prompts password immediately)
  final secret = vault.loadText('secret.txt');
  print(secret);
}
