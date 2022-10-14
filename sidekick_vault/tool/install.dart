import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_plugin_installer/sidekick_plugin_installer.dart';

Future<void> main(List<String> args) async {
  final cliPackage = DartPackage.fromDirectory(Directory(args[0]))!;
  print('installing vault in $cliPackage');

  const cliName = 'nh'; // TODO get from package manifest

  addPubDependency(cliPackage, 'sidekick_vault');
  // TODO?
  runPubGetOnCli();

  registerPlugin(
    sidekickCli: cliPackage,
    import: "import 'package:sidekick_vault/sidekick_vault.dart';",
    command: 'VaultCommand(vault: vault)',
  );

  // create vault file
  final vaultFile = cliPackage.root.file('lib/src/vault.dart');
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
  print('Wrote vault file');
}
