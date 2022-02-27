import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_vault/src/gpg.dart';

class VaultCommand extends Command {
  VaultCommand() {
    addSubcommand(_EncryptCommand());
    addSubcommand(_DecryptCommand());
  }

  @override
  String get description => 'Manages sidekick vault';

  @override
  String get name => 'vault';
}

class _EncryptCommand extends Command {
  @override
  String get description => 'Encrypts a file using gpg';

  @override
  String get name => 'encrypt';

  @override
  String? get usageFooter => '\n${green('Example usage:')}\n'
      '> $cliName vault encrypt file.csv';

  _EncryptCommand() {
    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'writes the file to this location',
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
    final file = _parseFileFromRest();
    final outFile = _parseOutFileOption();
    final password =
        _parsePassphraseOption() ?? ask('Enter password:', hidden: true);
    final encrypted = gpgEncrypt(file, password, output: outFile);
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
      '> $cliName vault decrypt file.csv.gpg';

  _DecryptCommand() {
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
    final file = _parseFileFromRest();
    final outFile = _parseOutFileOption();
    final password =
        _parsePassphraseOption() ?? ask('Enter password:', hidden: true);
    final decrypted = gpgDecrypt(file, password, output: outFile);
    print(
      green(
        'Successfully decrypted ${file.path} '
        'to ${decrypted.path}',
      ),
    );
  }
}

extension on Command {
  File _parseFileFromRest() {
    if (argResults!.rest.isEmpty) {
      _throwWithUsage('Missing file', usageFooter!);
    }
    if (argResults!.rest.length > 1) {
      _throwWithUsage('Enter one file only', usageFooter!);
    }
    final restArg = argResults!.rest.first;
    if (!isFile(restArg)) {
      _throwWithUsage('No valid file', usageFooter!);
    }
    return File(restArg);
  }

  File? _parseOutFileOption() {
    final result = argResults!['output'];
    if (result == null) {
      return null;
    }
    return File(result as String);
  }

  String? _parsePassphraseOption() {
    return argResults!['passphrase'] as String;
  }
}

void _throwWithUsage(String message, String usage) {
  error(
    '$message'
    '\n'
    '$usage',
  );
}
