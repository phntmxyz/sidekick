# Changelog

## [1.5.0](https://github.com/phntmxyz/sidekick/compare/sidekick_vault-v1.4.0..sidekick_vault-v1.5.0) (2026-1-13)

- **New**: decryptAll command [#277](https://github.com/phntmxyz/sidekick/pull/277) <https://github.com/phntmxyz/sidekick/commit/6c4e63ef53aabeab415d43c25bc7db7d9f6be217>
- **Improve** `change-password` command [#278](https://github.com/phntmxyz/sidekick/pull/278) <https://github.com/phntmxyz/sidekick/commit/20d1d9231a48dd180addf699e25b59d5d35d93db>
- Update to sidekick_core to 3.1.0 <https://github.com/phntmxyz/sidekick/commit/2ae21c4e2eafafaa7c876601ea591002d580a536>
- Upgrade dcli to 8.2.0 [#280](https://github.com/phntmxyz/sidekick/pull/280) <https://github.com/phntmxyz/sidekick/commit/d24ed64effcc958400e4bc292c7df50fed9af8a7>

<!--
Also package:sidekick_core updated (sidekick_core-v3.0.0 -> sidekick_core-v3.1.0), please consider those changes as well.
-->

sidekick_core diff: <https://github.com/phntmxyz/sidekick/compare/sidekick_core-v3.0.0...sidekick_core-v3.1.0>

## [1.4.0](https://github.com/phntmxyz/sidekick/compare/sidekick_vault-v1.3.0..sidekick_vault-v1.4.0) (2025-6-30)

Full diff: <https://github.com/phntmxyz/sidekick/compare/sidekick_vault-v1.3.0...main>

- Fully migrate to sidekick_core: 3.0.0 and sidekick_plugin_installer: 2.0.0 <https://github.com/phntmxyz/sidekick/commit/53784ccad1dcfe7776aaeb97c58081e02515a9db>
- Migrate comments <https://github.com/phntmxyz/sidekick/commit/0c0e5ed9a940331889f92c43affa0d19bfef4192>
- Update package description <https://github.com/phntmxyz/sidekick/commit/f61d12a6e71870ad48b51a57edf76f20a06ad0fe>

## [1.3.0](https://github.com/phntmxyz/sidekick/compare/sidekick_vault-v1.2.0..sidekick_vault-v1.3.0) (2025-4-14)

Full diff: https://github.com/phntmxyz/sidekick/compare/sidekick_vault-v1.2.0...main

- Update plugin installer to 1.3.0 and core to 3.0.0-preview.5
- Update min Dart Version to 3.5.0
- Update to dcli 7.0.2

## [1.2.0](https://github.com/phntmxyz/sidekick/compare/sidekick_vault-v1.1.0..sidekick_vault-v1.2.0) (2024-7-16)

- Update to dcli 4 https://github.com/phntmxyz/sidekick/commit/9a353e552ecf332824aa02f172b92c9f1b4ae884

## [1.1.0](https://github.com/phntmxyz/sidekick/compare/sidekick_vault-v1.0.0..sidekick_vault-v1.1.0) (2023-6-5)

- Update to sidekick_core: 2.0.0 (stable)

## [1.0.0](https://github.com/phntmxyz/sidekick/compare/sidekick_vault-v0.9.1..sidekick_vault-v1.0.0) (2023-5-30)

- Make sidekick_vault Dart 3 compatible

## [0.9.1](https://github.com/phntmxyz/sidekick/compare/sidekick_vault-v0.9.0..sidekick_vault-v0.9.1) (2023-5-11)

- Add topics to `pubspec.yaml`
- Update readme [#218](https://github.com/phntmxyz/sidekick/pull/218) https://github.com/phntmxyz/sidekick/commit/eb644414f6a7f3efb760b7ad06b3c55abd94d819
- Update `sidekick_core` dependency to `1.0.0`

## [0.9.0](https://github.com/phntmxyz/sidekick/compare/sidekick_vault-v0.8.1..sidekick_vault-v0.9.0) (2023-1-25)

- Update sidekick_core to 1.0.0 [#212](https://github.com/phntmxyz/sidekick/pull/212)

## [0.8.1](https://github.com/phntmxyz/sidekick/compare/sidekick_vault-v0.8.0..sidekick_vault-v0.8.1) (2023-1-22)

- Replace promts with dcli [#202](https://github.com/phntmxyz/sidekick/pull/202)

## [0.8.0](https://github.com/phntmxyz/sidekick/compare/sidekick_vault-v0.7.0..sidekick_vault-v0.8.0) (2023-1-22)

- Ask for vault path during install [#200](https://github.com/phntmxyz/sidekick/pull/200) https://github.com/phntmxyz/sidekick/commit/45f0ccca62b81dbb80ebf9d334c5d4a96565ffc4
- Update sidekick_plugin_installer [#193](https://github.com/phntmxyz/sidekick/pull/193) https://github.com/phntmxyz/sidekick/commit/8ab0c02882210dce07160816bedd9b507e5e1a03

## 0.7.0
- Fix folder creation bug during install (missing `await`) #110
- Improve error message when vault file doesn't exist #102
- Pub points: Add example / better repo link on pub / constrain `dcli` #106

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
