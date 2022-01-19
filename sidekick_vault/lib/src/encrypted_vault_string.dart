import 'package:sidekick_vault/sidekick_vault.dart';

/// Encrypted [String] from [vault] that is defined, but not directly parsed
///
/// Use it in cases where you don't want to directly encrypt the text (and
/// cause a password prompt). Instead, the prompt is delayed until [text] is
/// accessed.
class EncryptedVaultString {
  const EncryptedVaultString(this.vault, this.fileName);

  /// file name in vault
  final String fileName;

  final SidekickVault vault;

  String get text => vault.loadText(fileName);

  @override
  String toString() {
    return 'EncryptedVaultString{fileName: $fileName}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EncryptedVaultString &&
          runtimeType == other.runtimeType &&
          fileName == other.fileName;

  @override
  int get hashCode => fileName.hashCode;
}

extension EncryptedVaultStringExt on SidekickVault {
  EncryptedVaultString encryptedString(String filename) {
    return EncryptedVaultString(this, filename);
  }
}
