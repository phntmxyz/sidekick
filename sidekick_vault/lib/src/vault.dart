import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_vault/src/gpg.dart';
import 'package:sidekick_vault/src/logging.dart';

/// Grants access to project secrets stored gpg encrypted in this repository
class SidekickVault {
  /// Location of the directory containing vault files
  final Directory location;

  /// env name of the environment variable containing the passphrase to this vault
  ///
  /// i.e. FLT_VAULT_PASSPHRASE
  final String environmentVariableName;

  SidekickVault({
    required this.location,
    required this.environmentVariableName,
  });

  String? _passphrase;

  void unlock([String? passphrase]) {
    if (passphrase != null) {
      _passphrase = passphrase;
    } else {
      if (_passphrase != null) {
        return;
      }
      _passphrase = getEnvPassword(environmentVariableName);
    }
    assert(_passphrase != null);
  }

  /// Loads a file form the secure vault with [filename] to location [to] where
  /// it will be stored unencrypted. It is then returned.
  ///
  /// When [to] is null, the file returned is located in a temp directory
  File loadFile(String filename, {File? to}) {
    if (!filename.endsWith('.gpg')) {
      throw 'Files in vault always end with ".gpg". '
          '"$filename" does not';
    }
    unlock();
    final path = location.file(filename);
    if (!path.existsSync()) {
      throw "${path.path} does not exist in vault";
    }
    return gpgDecrypt(path, _passphrase!, output: to);
  }

  /// Saves the file in the vault.
  File saveFile(File file, {String? filename}) {
    unlock();
    final outFile = filename != null
        ? location.file(filename)
        : location.file('${file.name}.gpg');
    if (!outFile.path.endsWith('.gpg')) {
      throw 'Files in vault are required to end with ".gpg". '
          '"$filename" does not';
    }
    if (!file.existsSync()) {
      throw "${file.path} does not exist in vault";
    }
    return gpgEncrypt(file, _passphrase!, output: outFile);
  }

  // caches secrets to prevent multiple decryption
  final Map<String, String> _cache = {};

  String loadText(String filename) {
    if (_cache.containsKey(filename)) {
      return _cache[filename]!;
    }
    final file = loadFile(filename);
    final secret = file.readAsStringSync();
    maskSecret(secret);
    _cache[filename] = secret;
    return secret;
  }

  List<File> listEntries() {
    final files = location.listSync().whereType<File>();

    final fileList = files
        .where((file) => file.name.endsWith('.gpg'))
        .sortedBy((file) => file.path)
        .toList();

    return fileList;
  }
}

/// Read a password from [env], asks user via stdin when not available
String getEnvPassword(String envKey, [String? name]) {
  final String? password = dcli.env[envKey];
  if (password != null) {
    return password;
  }

  // Could not resolve password from env, ask user for password in shell
  final userInput = dcli
      .ask(
        'Enter ${name ?? envKey} password (or provide env.$envKey):',
        hidden: true,
      )
      .trim();

  // On CI without stdin the userInput returns ""
  if (userInput.isEmpty) {
    throw "Password in env.$envKey is not defined and user input was empty";
  }

  return userInput;
}
