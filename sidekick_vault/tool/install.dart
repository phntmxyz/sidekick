import 'package:sidekick_core/sidekick_core.dart'
    hide cliName, repository, mainProject;
import 'package:sidekick_plugin_installer/sidekick_plugin_installer.dart';

Future<void> main(List<String> args) async {
  // The installer injects the path to the sidekick project as first argument
  final package = SidekickPackage.fromDirectory(Directory(args[0]))!;

  pubAddDependency(package, 'sidekick_vault');
  pubGet(package);

  registerPlugin(
    sidekickCli: package,
    import: "import 'package:sidekick_vault/sidekick_vault.dart';",
    command: 'VaultCommand(vault: vault)',
  );
  _writeVaultFile(package);
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
  location: ${cliName}Project.${cliName}SidekickPackage.root.directory('vault'),
  environmentVariableName: '${cliName.toUpperCase()}_VAULT_PASSPHRASE',
);
  ''');
}
