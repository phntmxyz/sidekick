import 'package:sidekick_core/sidekick_core.dart'
    hide cliName, repository, mainProject;
import 'package:sidekick_plugin_installer/sidekick_plugin_installer.dart';

Future<void> main(List<String> args) async {
  // The installer injects the path to the sidekick project as first argument
  final package = SidekickPackage.fromDirectory(Directory(args[0]))!;

  pubAddDependency(package, 'sidekick_vault');
  pubGet(package);

  _writeVaultFile(package);
  addImport(
    package.libDir.file('${package.name}.dart'),
    "import 'package:${package.name}/src/vault.dart';",
  );



  registerPlugin(
    sidekickCli: package,
    import: "import 'package:sidekick_vault/sidekick_vault.dart';",
    command: 'VaultCommand(vault: vault)',
  );
  _createVaultFolder(package);

  print(_usage(package));
}

void _writeVaultFile(SidekickPackage package) {
  final vaultFile = package.root.file('lib/src/vault.dart');

  final cliName = package.cliName;
  vaultFile.writeAsStringSync('''
import 'package:sidekick_vault/sidekick_vault.dart';

import 'package:${cliName}_sidekick/${cliName}_sidekick.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_vault/sidekick_vault.dart';

final SidekickVault vault = SidekickVault(
  location: ${cliName}Project.root.directory('vault'),
  environmentVariableName: '${cliName.toUpperCase()}_VAULT_PASSPHRASE',
);
  ''');
}

void _createVaultFolder(SidekickPackage package) {
  final folder = package.root.directory('vault');
  if (!folder.existsSync()) {
    folder.create();
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

String _usage(SidekickPackage package) => """

${white('vault usage:')}

  ${white('Add item to vault:')}
    \$ ${package.cliName} vault add ~/Downloads/my_secret.txt
    
    => File is saved as ${package.name}/vault/my_secret.txt.gpg
  
  ${white('Use secret in code:')}
    ```dart
    final File decryptedFile = vault.loadFile('my_secret.txt.gpg');
    final String decryptedText = vault.loadText('my_secret.txt.gpg');
    print('Secret: \$decryptedText');
    ```

    => CLI will prompt for the password
       or reads the value of env.${package.cliName.toUpperCase()}_VAULT_PASSPHRASE
""";
