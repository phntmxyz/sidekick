import 'package:path/path.dart' show absolute;
import 'package:sidekick_core/sidekick_core.dart';

/// The package that contains the generated sidekick cli code
class SidekickPackage extends DartPackage {
  SidekickPackage(super.root, super.name);

  static SidekickPackage? fromDirectory(Directory directory) {
    final dartPackage = DartPackage.fromDirectory(directory);
    if (dartPackage == null) {
      return null;
    }

    return SidekickPackage(dartPackage.root, dartPackage.name);
  }

  /// The name of the sidekick cli
  String get cliName => name.replaceAll('_sidekick', '');

  SidekickDartRuntime get dartRuntime => SidekickDartRuntime(root);

  /// Main file of the CLI plugins are registered where
  File get cliMainFile {
    return libDir.file('$name.dart');
  }

  @override
  String toString() => "SidekickPackage '$name' (${absolute(root.path)})";
}
