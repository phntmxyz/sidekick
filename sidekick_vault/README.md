# Sidekick Vault

A place to store project secrets within a git repository, encrypted with GPG


# Create the Vault

1. Create a `vault` directory in your project

2. Place a `README.md` in `vault`

    ````markdown
    # Vault
    
    This vault contains gpg encrypted passwords and certificates.
    
    To get the password to the vault ask one of the administrators.
    This password is available on CI as environment variable `FLT_VAULT_PASSPHRASE`
    
    ## Encrypt secrets
    
    ```
    gpg --symmetric --cipher-algo AES256 --batch --passphrase=$password <file>
    ```
    
    ## Decrypt secrets
    
    ```sdfg
    gpg --quiet --batch --yes --decrypt --passphrase=$password --output=<file> <file.gpg>
    ```
    ````

3. Place a `.gitignore` in `vault`

    ```gitignore
    # Ignore everything in this folder which isn't gpg encrypted
    *
    !*.gpg
    
    # Exceptions
    !README.md
    !.gitignore
    ```

## Add secrets

1. Generate a secure password in your preferred password manager

2. Place the first secret in your vault. I.e. `secret.txt` and encrypt it with
   
   `gpg --symmetric --cipher-algo AES256 --batch --passphrase=Y0UR-P4$$W0RD vault/secret.txt`

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