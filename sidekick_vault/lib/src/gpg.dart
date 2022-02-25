import 'package:dcli/dcli.dart';
import 'package:sidekick_core/sidekick_core.dart';

/// Checks if gpg is installed.
void _requireGpg() {
  if (!isProgramInstalled('gpg')) {
    print('Attempt to install required program "gpg"');
    if (Platform.isMacOS) {
      'brew install gnupg'.run;
    } else {
      throw 'gpg not installed';
    }
  }
}

extension GpgEncrypt on File {
  /// Encrypts the file using gpg.
  void encrypt(String password) {
    _requireGpg();
    startFromArgs('gpg', [
      '--symmetric',
      '--cipher-algo',
      'AES256',
      '--batch',
      '--passphrase=$password',
      this.absolute.path,
    ]);
  }
}

extension GpgDecrypt on File {
  /// Decrypts the file using gpg.
  void decrypt(String password, [String? output]) {
    _requireGpg();
    startFromArgs('gpg', [
      '--quiet',
      '--batch',
      '--yes',
      '--decrypt',
      '--passphrase=$password',
      '--output=${output ?? nameWithoutExtension}',
      this.absolute.path,
    ]);
  }

  /// Returns the decrypted file located in a temp directory.
  File decryptToTemp(String password) {
    final outDir = Directory.systemTemp.createTempSync();
    final outFile = outDir.file(nameWithoutExtension);

    decrypt(password, outFile.absolute.path);

    assert(outFile.existsSync());
    return outFile;
  }
}
