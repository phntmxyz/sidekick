import 'package:sidekick_core/sidekick_core.dart';

class SkProject {
  SkProject(this.root);

  final Directory root;

  DartPackage get sidekickPackage =>
      DartPackage.fromDirectory(root.directory('sidekick'))!;

  DartPackage get sidekickVaultPackage =>
      DartPackage.fromDirectory(root.directory('sidekick_vault'))!;

  DartPackage get skSidekickPackage =>
      DartPackage.fromDirectory(root.directory('sk_sidekick'))!;

  DartPackage get sidekickPluginInstallerPackage =>
      DartPackage.fromDirectory(root.directory('sidekick_plugin_installer'))!;

  DartPackage get sidekickCorePackage =>
      DartPackage.fromDirectory(root.directory('sidekick_core'))!;
}
