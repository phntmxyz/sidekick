import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_core/sidekick_core.dart';

/// Checks that gpg is installed
void requireGpg() {
  if (!isProgramInstalled('gpg')) {
    print('Attempt to install required program "gpg"');
    if (Platform.isMacOS) {
      'brew install gnupg'.run;
    } else {
      throw 'gpg not installed';
    }
  }
}

/// Returns the decrypted file located in a temp directory
File gpgDecrypt(File file, String password) {
  requireGpg();
  final outDir = Directory.systemTemp.createTempSync();
  final outFile = outDir.file(file.nameWithoutExtension);

  dcli.startFromArgs('gpg', [
    '--quiet',
    '--batch',
    '--yes',
    '--decrypt',
    '--passphrase=$password',
    '--output=${outFile.absolute.path}',
    file.absolute.path,
  ]);
  assert(outFile.existsSync());
  return outFile;
}
