import 'package:dcli/dcli.dart' as dcli;
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
  Future<void> run() async {
    final file = _validateInput(argResults, example: 'noa vault encrypt file.csv');
    final password = dcli.ask('Enter password:', hidden: true);
    file.encrypt(password);
    print(green('Successfully encrypted $file'));
  }
}

class _DecryptCommand extends Command {
  @override
  String get description => 'Decrypts a file using gpg';

  @override
  String get name => 'decrypt';

  @override
  Future<void> run() async {
    final file = _validateInput(argResults, example: 'noa vault decrypt file.csv.gpg');
    final password = dcli.ask('Enter password:', hidden: true);
    file.decrypt(password);
    print(green('Successfully decrypted $file'));
  }
}

File _validateInput(ArgResults? input, {required String example}) {
  if (input?.arguments.isEmpty ?? false) {
    _throw('Missing file', example);
  }
  if (input!.arguments.length > 1) {
    _throw('Enter one file only', example);
  }
  if (!dcli.isFile(input.arguments.first)) {
    _throw('No valid file', example);
  }
  return File(input.arguments.first);
}

void _throw(String message, String example) {
  error(
    '$message'
    '\n'
    'Example:\n'
    '$example',
  );
}
