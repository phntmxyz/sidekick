import 'dart:io';

import 'package:dartx/dartx_io.dart';
import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_vault/src/gpg.dart';

/// Grants access to project secrets stored gpg encrypted in this repository
class SidekickVault {
  /// Location of the directory containing vault files
  final Directory location;

  /// env name of the environment variable containing the passphrase to this vault
  ///
  /// i.e. FLT_VAULT_PASSPHRASE
  final String environmentVariableName;

  SidekickVault({required this.location, required this.environmentVariableName});

  String? _passphrase;

  void unlock() {
    if (_passphrase != null) {
      return;
    }
    _passphrase = getEnvPassword(environmentVariableName);
    assert(_passphrase != null);
  }

  File loadFile(String filename) {
    if (!filename.endsWith('.gpg')) {
      throw 'expect file to end with .gpg';
    }
    unlock();
    return gpgDecrypt(location.file(filename), _passphrase!);
  }

  // caches secrets to prevent multiple decryptions
  final Map<String, String> _cache = {};

  String loadText(String filename) {
    if (_cache.containsKey(filename)) {
      return _cache[filename]!;
    }
    final file = loadFile(filename);
    final secret = file.readAsStringSync();
    _cache[filename] = secret;
    return secret;
  }
}

/// Read a password from [env], asks user via stdin when not available
String getEnvPassword(String envKey, [String? name]) {
  final String? password = dcli.env[envKey];
  if (password != null) {
    return password;
  }
  return dcli.ask('Enter ${name ?? envKey} password (or provide env.$envKey):', hidden: true).trim();
}
