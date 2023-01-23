import 'package:dcli/dcli.dart' as dcli;
import 'package:sidekick_core/sidekick_core.dart'
    hide cliName, repository, mainProject;
import 'package:sidekick_plugin_installer/sidekick_plugin_installer.dart';

Future<void> main() async {
  final SidekickPackage package = PluginContext.sidekickPackage;

  final repoRoot = findRepository().root;
  print('${green('Where do you want to create the vault directory?')} '
      '(Relative to ${repoRoot.path})');
  final vaultPath = dcli.ask(
    'vault path:',
    validator: _IsWithinDirectoryValidator(repoRoot),
    defaultValue:
        relative(repoRoot.directory('vault').path, from: repoRoot.path),
  );
  final vaultDir = repoRoot.directory(vaultPath);

  print("- Adding sidekick_vault as dependency");
  addSelfAsDependency();
  pubGet(package);

  print("- Generating package:${package.name}/src/vault.dart");
  _writeVaultFile(vaultDir, package);
  addImport(
    package.libDir.file('${package.name}.dart'),
    "import 'package:${package.name}/src/vault.dart';",
  );

  print("- Adding vault command");
  registerPlugin(
    sidekickCli: package,
    import: "import 'package:sidekick_vault/sidekick_vault.dart';",
    command: 'VaultCommand(vault: vault)',
  );

  print("- Creating vault at ${vaultDir.path}");
  _createVaultFolder(vaultDir, package);

  print(_usage(relative(vaultDir.path), package));
}

void _writeVaultFile(Directory vault, SidekickPackage package) {
  final vaultFile = package.root.file('lib/src/vault.dart');
  final vaultDirRelativeToPackage =
      relative(vault.path, from: package.root.path);

  final cliName = package.cliName;
  vaultFile.writeAsStringSync('''
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_vault/sidekick_vault.dart';

final SidekickVault vault = SidekickVault(
  location: Repository.requiredSidekickPackage.root.directory('$vaultDirRelativeToPackage'),
  environmentVariableName: '${cliName.toUpperCase()}_VAULT_PASSPHRASE',
);
''');
}

void _createVaultFolder(Directory folder, SidekickPackage package) {
  if (!folder.existsSync()) {
    folder.createSync();
  }

  final readme = folder.file('README.md');
  if (!readme.existsSync()) {
    readme.writeAsStringSync('''
# ${package.cliName.capitalize()} Vault

This vault contains gpg encrypted passwords and certificates.

To get the password to the vault ask one of the administrators.

This password is available on CI as environment variable `${package.cliName.toUpperCase()}_VAULT_PASSPHRASE`.

## List existing secrets

```
${package.cliName} vault list
```

## Encrypt secrets

```
${package.cliName} vault encrypt file.csv
```

## Decrypt secrets

```
${package.cliName} vault decrypt file.csv.gpg
```
    ''');

    final gitignore = folder.file('.gitignore');
    if (!gitignore.existsSync()) {
      gitignore.writeAsStringSync('''
# Ignore everything in this folder which isn't gpg encrypted
*
!*.gpg

# Exceptions
!README.md
!.gitignore
      ''');
    }
  }
}

String _usage(String vaultPath, SidekickPackage package) => """

${white('vault usage:')}

  ${white('Add item to vault:')}
    \$ ${package.cliName} vault encrypt ~/Downloads/my_secret.txt
    
    => File is saved as $vaultPath/my_secret.txt.gpg
  
  ${white('Use secret in code:')}
    ```dart
    final File decryptedFile = vault.loadFile('my_secret.txt.gpg');
    final String decryptedText = vault.loadText('my_secret.txt.gpg');
    print('Secret: \$decryptedText');
    ```

    => CLI will prompt for the password
       or reads the value of env.${package.cliName.toUpperCase()}_VAULT_PASSPHRASE
""";

class _IsWithinDirectoryValidator extends dcli.AskValidator {
  final Directory directory;

  _IsWithinDirectoryValidator(this.directory);

  @override
  String validate(String line) {
    final dir = Directory(line);
    if (!dir.isWithin(directory)) {
      throw AskValidatorException('Not within ${directory.path}');
    }
    return line;
  }
}
