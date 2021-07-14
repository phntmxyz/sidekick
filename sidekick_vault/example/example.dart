import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_vault/sidekick_vault.dart';

void main() {
  final vault = SidekickVault(
    location: repository.root.directory('vault'),
    // environment variable where CIs can inject the vault password
    environmentVariableName: 'FLT_VAULT_PASSPHRASE',
  );

  final secret = vault.loadText('secret.txt');

  // Use secret on your CI to do magic things
}
