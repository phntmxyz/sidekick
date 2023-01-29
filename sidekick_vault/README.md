# Sidekick Vault

A place to store project secrets within a git repository, encrypted with GPG

## Manage vault with VaultCommand

### Add file to vault

```bash
<cli-name> vault encrypt path/to/secret.csv
```

```bash
<cli-name> vault encrypt --passphrase="****" --vault-location="secret.txt.gpg" path/to/secret.txt
```

The `passphrase` is optional.
It will be retrieved from the environment variables or asked via `stdin`.

The file will be saved at `vault-location` (optional) inside the vault directory.
The filename (`secret.txt`) will be used as fallback.

### Decrypt file in vault

```bash
<cli-name> vault encrypt secret.csv.gpg
```

```bash
<cli-name> vault decrypt --passphrase="****" --output="write/to/decrypted.txt" secret.txt.gpg';
```

The `passphrase` is optional.
It will be retrieved from the environment variables or asked via `stdin`.

`output` is optional.
The decrypted file will be saved in the vault next to the encrypted one (without `.gpg` ending).

### Change vault password

```bash
<cli-name> vault change-password
```

```bash
<cli-name> vault change-password --old ***** --new *****
```

Use the `old` and `new` arguments to pass the old and new password.
Without the arguments, you can enter the passwords via `stdin`.

## Manually add/read items in vault via gpg

### Add file to vault

```bash
gpg --symmetric --cipher-algo AES256 --batch --passphrase=$password <file>
```

### Decrypt file from vault

```bash
gpg --quiet --batch --yes --decrypt --passphrase=$password --output=<file> <file.gpg>
```

## Read secrets in code

Create a vault in your sidekick cli and read the password

```dart
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
```
