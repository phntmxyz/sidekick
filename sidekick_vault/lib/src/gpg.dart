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

/// Encrypts the file using gpg.
File gpgEncrypt(File file, String password, {File? output}) {
  _requireGpg();

  final outputFile = output ??
      () {
        final outDir = Directory.systemTemp.createTempSync();
        return outDir.file(file.nameWithoutExtension);
      }();

  startFromArgs('gpg', [
    '--symmetric',
    '--cipher-algo',
    'AES256',
    '--batch',
    '--passphrase=$password',
    '--output=${outputFile.absolute.path}',
    file.absolute.path,
  ]);

  assert(outputFile.existsSync());
  return outputFile;
}

/// Decrypts the file using gpg.
File gpgDecrypt(File file, String password, {File? output}) {
  _requireGpg();

  final outputFile = output ??
      () {
        final outDir = Directory.systemTemp.createTempSync();
        return outDir.file(file.nameWithoutExtension);
      }();

  startFromArgs('gpg', [
    '--quiet',
    '--batch',
    '--yes',
    '--decrypt',
    '--passphrase=$password',
    '--output=${outputFile.absolute.path}',
    file.absolute.path,
  ]);

  assert(outputFile.existsSync());
  return outputFile;
}
