import 'package:sidekick_core/sidekick_core.dart';
import 'package:sidekick_core/src/directory_ext.dart';
import 'package:yaml/yaml.dart';

class DartPackage {
  DartPackage(this.root, this.name) : isFlutterPackage = false;

  DartPackage.flutter(this.root, this.name) : isFlutterPackage = true;

  /// Returns [DartPackage] if a directory fulfils the requirements of a Dart/Flutter package
  /// - pubspec.yaml
  /// - name in pubspec.yaml
  /// (- flutter dependency)
  static DartPackage? fromDirectory(Directory directory) {
    final normalizedDir = Directory(normalize(directory.path));
    final pubspec = normalizedDir.file('pubspec.yaml');
    if (!pubspec.existsSync()) {
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
      final deps = pubspec['dependencies'] as YamlMap?;
      final flutterDep = deps?['flutter'] as YamlMap?;
      if (flutterDep != null) {
        return DartPackage.flutter(normalizedDir, packageName);
      }
      return DartPackage(normalizedDir, packageName);
    } on YamlException {
      return null;
    }
  }

  /// Returns [DartPackage] from first argument in [argResults.rest] or if [argResults.rest] is empty from [entryWorkingDirectory]
  static DartPackage fromArgResults(ArgResults argResults) {
    {
      final packagePath =
          argResults.rest.firstOrNull ?? entryWorkingDirectory.path;
      final package = DartPackage.fromDirectory(Directory(packagePath));
      if (package == null) {
        throw 'Could not find a package in $packagePath';
      }
      return package;
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

  File get lockfile => root.file('pubspec.lock');

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
          canonicalize(root.path) == canonicalize(other.root.path);

  @override
  int get hashCode => canonicalize(root.path).hashCode;

  @override
  String toString() => "DartPackage '$name'";
}

/// Returns true when the name is a valid pub package name according to
/// https://dart.dev/tools/pub/pubspec#name
///
/// The name should be all lowercase, with underscores to separate words,
/// just_like_this.
/// Use only basic Latin letters and Arabic digits: [a-z0-9_].
/// Also, make sure the name is a valid Dart identifier—that it doesn’t
/// start with digits and isn’t a reserved word (keyword).
bool isValidPubPackageName(String name) {
  return _cliNameRegExp.hasMatch(name) && !_keywords.contains(name);
}

/// Returns the list of all packages in the repository
List<DartPackage> findAllPackages(Directory directory) {
  return directory
      .allSubDirectories((dir) {
        if (dir.name.startsWith('.')) {
          // ignore hidden folders
          return false;
        }
        if (dir.name == 'build') {
          final package = DartPackage.fromDirectory(dir.parent);
          if (package != null) {
            // ignore <dartPackage>/build dir
            return false;
          }
        }
        return true;
      })
      .mapNotNull((it) => DartPackage.fromDirectory(it))
      .toList();
}

/// https://github.com/dart-lang/sdk/blob/8d262e294400d2f7e41f05579c088a6409a7b2bb/pkg/dartdev/lib/src/utils.dart#L95
final RegExp _cliNameRegExp = RegExp(r'^[a-z_][a-z\d_]*$');

/// https://github.com/dart-lang/sdk/blob/8d262e294400d2f7e41f05579c088a6409a7b2bb/pkg/dartdev/lib/src/utils.dart#L99
const Set<String> _keywords = <String>{
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'function',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'inout',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'native',
  'new',
  'null',
  'of',
  'on',
  'operator',
  'out',
  'part',
  'patch',
  'required',
  'rethrow',
  'return',
  'set',
  'show',
  'source',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'while',
  'with',
  'yield',
};
