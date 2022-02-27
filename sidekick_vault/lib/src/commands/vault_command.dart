import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_vault/sidekick_vault.dart';

class VaultCommand extends Command {
  VaultCommand({required SidekickVault vault}) {
    addSubcommand(_EncryptCommand(vault));
    addSubcommand(_DecryptCommand(vault));
    addSubcommand(_ListCommand(vault));
  }

  @override
  String get description => 'Manages sidekick vault';

  @override
  String get name => 'vault';
}

class _ListCommand extends Command {
  @override
  String get description => 'lists the secrets in vault';

  @override
  String get name => 'list';

  final SidekickVault vault;

  _ListCommand(this.vault);

  @override
  Future<void> run() async {
    final files = vault
        .listEntries()
        .map((file) => relative(file.path, from: vault.location.path));
    print(files.joinToString(separator: '\n'));
  }
}

class _EncryptCommand extends Command {
  @override
  String get description => 'Encrypts a file using gpg';

  @override
  String get name => 'encrypt';

  @override
  String? get usageFooter => '\n${green('Example usage:')}\n'
      '> $cliName vault encrypt secret.txt.gpg\n'
      '> $cliName vault encrypt --passpharse="****" --vault-location="secret.txt.gpg" path/to/secret.txt';

  final SidekickVault vault;

  _EncryptCommand(this.vault) {
    argParser.addOption(
      'vault-location',
      abbr: 'l',
      help: 'writes the file to this location in vault. '
          'Defaults to "<file>.gpg" in root of the vault',
    );
    argParser.addOption(
      'passphrase',
      abbr: 'p',
      help: 'the password for encryption. '
          'If not provided it will be asked via stdin',
    );
  }

  @override
  Future<void> run() async {
    final file = File(_parseFileFromRest());
    final location = _parseVaultLocation();
    final password = _parsePassphraseOption();
    vault.unlock(password);

    final encrypted = vault.saveFile(file, filename: location);

    print(
      green(
        'Successfully encrypted ${file.path} '
        'to ${encrypted.path}',
      ),
    );
  }
}

class _DecryptCommand extends Command {
  @override
  String get description => 'Decrypts a file using gpg';

  @override
  String get name => 'decrypt';

  @override
  String? get usageFooter => '\n${green('Example usage:')}\n'
      '> $cliName vault decrypt secret.txt.gpg\n'
      '> $cliName vault decrypt --passpharse="****" --output="write/to/decrypted.txt" secret.txt.gpg';

  final SidekickVault vault;

  _DecryptCommand(this.vault) {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'writes the file to this location',
    );
    argParser.addOption(
      'passphrase',
      abbr: 'p',
      help: 'the password for decryption. '
          'If not provided it will be asked via stdin',
    );
  }

  @override
  Future<void> run() async {
    final vaultLocation = _parseFileFromRest();
    final outFile = _parseOutFileOption() ??
        vault.location.file(vaultLocation.replaceFirst('.gpg', ''));
    final password = _parsePassphraseOption();
    vault.unlock(password);

    final decrypted = vault.loadFile(vaultLocation, to: outFile);
    print(
      green(
        'Successfully decrypted $vaultLocation '
        'to ${decrypted.path}',
      ),
    );
  }
}

extension on Command {
  String _parseFileFromRest() {
    if (argResults!.rest.isEmpty) {
      _throwWithUsage('Missing file', usageFooter!);
    }
    if (argResults!.rest.length > 1) {
      _throwWithUsage('Enter one file only', usageFooter!);
    }
    final restArg = argResults!.rest.first;
    return restArg;
  }

  File? _parseOutFileOption() {
    final result = argResults!['output'];
    if (result == null) {
      return null;
    }
    return File(result as String);
  }

  String? _parseVaultLocation() {
    return argResults!['vault-location'] as String?;
  }

  String? _parsePassphraseOption() {
    return argResults!['passphrase'] as String?;
  }
}

void _throwWithUsage(String message, String usage) {
  error(
    '$message'
    '\n'
    '$usage',
  );
}
