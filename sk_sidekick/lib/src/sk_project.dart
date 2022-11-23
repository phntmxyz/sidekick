import 'package:sidekick_core/sidekick_core.dart';

class SkProject {
  SkProject(this.root);

  final Directory root;

  DartPackage get sidekickPackage =>
      DartPackage.fromDirectory(root.directory('sidekick'))!;

  DartPackage get minimalSidekickPluginPackage => DartPackage.fromDirectory(
      root.directory('sidekick/test/templates/minimal_sidekick_plugin'))!;

  DartPackage get sidekickVaultPackage =>
      DartPackage.fromDirectory(root.directory('sidekick_vault'))!;

  DartPackage get skSidekickPackage =>
      DartPackage.fromDirectory(root.directory('sk_sidekick'))!;

  DartPackage get sidekickPluginInstallerPackage =>
      DartPackage.fromDirectory(root.directory('sidekick_plugin_installer'))!;

  DartPackage get sidekickCorePackage =>
      DartPackage.fromDirectory(root.directory('sidekick_core'))!;

  File get flutterw => root.file('flutterw');

  List<DartPackage>? _packages;
  List<DartPackage> get allPackages {
    return _packages ??= root
        .directory('packages')
        .listSync()
        .whereType<Directory>()
        .mapNotNull((it) => DartPackage.fromDirectory(it))
        .toList();
  }
}
