## 0.6.0
- Added plugin installer. You can now install the sidekick_vault plugin with `<cli> sidekick plugin install sidekick_vault`

## 0.5.4

- Updates dependency `actions_toolkit_dart` to `^0.5.0`
- `vault encrypt` now overwrites existing files

## 0.5.3

- Updates dependency `actions_toolkit_dart` to `^0.4.1`
- Add `vault.deleteFile(File)`

## 0.5.2

- Makes `maskSecret` public to hide secrets in the github actions log

## 0.5.1

- Secrets read via `vault.loadText()` will be hidden on GitHub Actions.   

## 0.5.0

- Add `<cli-name> vault change-password` command to change the vault password

## 0.4.0

- Throw on CI when no passphrase is provided via stdin
- Adds `VaultCommand`, allowing adding and reading secrets via a sidekick cli
    ```dart
    // Add command to your CLI
    ..addCommand(VaultCommand(vault: vault)) 
    ```
    
    ### Add file to vault
    
    ```bash
    <cli-name> vault encrypt path/to/secret.csv
    ```
    
    ```bash
    <cli-name> vault encrypt --passpharse="****" --vault-location="secret.txt.gpg" path/to/secret.txt
    ```
    
    The `passpharse` is optional.
    It will be retrieved from the environment variables or asked via `stdin`.
    
    The file will be saved at `vault-location` (optional) inside the vault directory.
    The filename (`secret.txt`) will be used as fallback.

    ### Decrypt file in vault
    
    ```bash
    <cli-name> vault encrypt secret.csv.gpg
    ```
    
    ```bash
    <cli-name> vault decrypt --passpharse="****" --output="write/to/decrypted.txt" secret.txt.gpg';
    ```
    
    The `passpharse` is optional.
    It will be retrieved from the environment variables or asked via `stdin`.
    
    `output` is optional.
    The decrypted file will be saved in the vault next to the encrypted one (without `.gpg` ending).
    

## 0.3.0

- Requires Dart 2.14
- New `EncryptedVaultString` defines a value in `vault` before accessing it. Use `text` to access the content and prompt for the password
- Use the `Vault.encryptedString(String fileName)` extension to create a `EncryptedVaultString`

## 0.2.0

- Document and add example

## 0.1.0

- First release