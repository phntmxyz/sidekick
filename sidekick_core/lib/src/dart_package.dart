import 'package:sidekick_core/sidekick_core.dart';
import 'package:yaml/yaml.dart';

class DartPackage {
  DartPackage(this.root, this.name) : isFlutterPackage = false;
  DartPackage.flutter(this.root, this.name) : isFlutterPackage = true;

  /// Returns [DartPackage] if a dictionary fulfils the requirements of a Dart/Flutter package
  /// - pubspec.yaml
  /// - lib directory
  /// - name in pubspec.yaml
  /// (- flutter dependency)
  static DartPackage? fromDirectory(Directory directory) {
    final pubspec = directory.file('pubspec.yaml');
    if (!pubspec.existsSync()) {
      return null;
    }
    final lib = directory.directory('lib');
    if (!lib.existsSync()) {
      printerr(
        'Detected a pubspec.yaml in ${directory.absolute.path} but the /lib directory is missing. '
        'The directory will not be interpreted as valid Dart package.',
      );
      return null;
    }
    final pubspecYamlContent = pubspec.readAsStringSync();
    try {
      // Check for valid package name
      final doc = loadYamlDocument(pubspecYamlContent);
      final pubspec = doc.contents.value as YamlMap;
      final packageName = pubspec['name'] as String?;
      if (packageName == null) {
        return null;
      }

      // Check for (optional) flutter dependency
      final deps = pubspec['dependencies'] as Map?;
      final flutterDep = deps?['flutter'] as YamlMap?;
      if (flutterDep != null) {
        return DartPackage.flutter(directory, packageName);
      }
      return DartPackage(directory, packageName);
    } on YamlException {
      return null;
    }
  }

  /// The directory the package is located on disk
  final Directory root;

  /// The `build` directory where build outputs can be placed
  Directory get buildDir => root.directory('build');

  /// The `bin` directory containing entrypoints for CLIs
  Directory get binDir => root.directory('bin');

  /// The `lib` directory containing the packages source code
  Directory get libDir => root.directory('lib');

  /// The `test` directory containing unit tests
  Directory get testDir => root.directory('test');

  /// The `tool` directory containing helper scripts
  Directory get toolDir => root.directory('tool');

  File get pubspec => root.file('pubspec.yaml');

  /// Set of directories containing dart source code
  Set<Directory> get srcDirs => {binDir, libDir, testDir, toolDir};

  /// `true` when the package has a dependency on `flutter`, thus requires the flutter_tool, not pub to get dependencies
  final bool isFlutterPackage;

  /// The package name defined in the pubspec.yaml
  ///
  /// The package name might be different from the directory the package is placed in
  final String name;

  /// Returns true when the provided path is in context of this package
  bool containsPath(FileSystemEntity entity) {
    return root.path == entity.path || root.containsSync(entity);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DartPackage &&
          runtimeType == other.runtimeType &&
          root.path == other.root.path;

  @override
  int get hashCode => root.path.hashCode;

  @override
  String toString() => "DartPackage '$name'";
}
