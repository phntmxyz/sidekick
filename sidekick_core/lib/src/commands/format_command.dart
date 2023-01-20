import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:meta/meta.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:yaml/yaml.dart';

/// Formats the Code for all Flutter/Dart packages in the repository
class FormatCommand extends Command {
  @override
  String get description => 'Formatting the code for all packages';

  @override
  String get name => 'format';

  /// packages whose files should not be formatted
  final List<DartPackage> exclude;

  /// glob patterns of packages whose dependencies should not be loaded
  ///
  /// Search starts at repository root.
  ///
  /// Example project layout:
  ///
  /// ```
  /// repo-root
  /// ├── packages
  /// │   ├── package1
  /// │   ├── package2
  /// │   └── circle
  /// └── third_party
  ///     ├── circle
  ///     │   ├── packageA
  ///     │   └── packageB
  ///     └── square
  /// ```
  ///
  /// - Use `packages/package1/**` to exclude only `packages/package1`.
  /// - Use `**/circle/**` to exclude `packages/circle` as well as
  ///   `third_party/circle/packageA` and `third_party/circle/packageB`.
  final List<String> excludeGlob;

  FormatCommand({
    this.exclude = const [],
    this.excludeGlob = const [],
  }) {
    argParser.addOption(
      'package',
      abbr: 'p',
    );
    argParser.addOption(
      'line-length',
      abbr: 'l',
    );
  }

  @override
  Future<void> run() async {
    final String? packageName = argResults?['package'] as String?;
    final int? lineLength =
        int.tryParse(argResults?['line-length'] as String? ?? '');

    final List<DartPackage> allPackages = repository.findAllPackages();

    if (packageName != null) {
      final package =
          allPackages.where((it) => it.name == packageName).firstOrNull;
      if (package == null) {
        throw "Package with name $packageName not found in repository "
            "${repository.root.path}";
      }
      // only format for selected package
      _format(package, globalLineLength: lineLength);
      return;
    }

    final errorBuffer = StringBuffer();

    final globExcludes = excludeGlob
        .expand((rule) {
          // start search at repo root
          final root = repository.root.path;
          return Glob("$root/$rule").listSync(root: root);
        })
        .whereType<Directory>()
        .mapNotNull((e) => DartPackage.fromDirectory(e));

    final excluded = [
      ...exclude,
      ...globExcludes,
    ];

    for (final package in allPackages.whereNot(excluded.contains)) {
      try {
        _format(package, globalLineLength: lineLength);
      } catch (e, stack) {
        print('Error while formatting Code for ${package.name} '
            '(${package.root.path})');
        errorBuffer.writeln("${package.name}: $e\n$stack");
      }
    }
    final errorText = errorBuffer.toString();
    if (errorText.isNotEmpty) {
      printerr("\n\nErrors while formatting:");
      printerr(errorText);
      exitCode = 1;
    }
  }
}

void _format(DartPackage package, {int? globalLineLength}) {
  print(yellow('=== package ${package.name} ==='));
  final int exitCode;
  final int lineLength = globalLineLength ?? getLineLength(package);
  if (package.isFlutterPackage) {
    exitCode = flutter(
      ['format', '-l', '$lineLength', package.root.path],
      workingDirectory: package.root,
    );
  } else {
    exitCode = dart(
      ['format', '-l', '$lineLength', package.root.path],
      workingDirectory: package.root,
    );
  }
  if (exitCode != 0) {
    throw "Failed to get dependencies for package ${package.root.path}";
  }
  print("\n");
}

@visibleForTesting
int getLineLength(DartPackage package) {
  final yamlFile = package.root.file('pubspec.yaml').readAsStringSync();
  final pubspecData = loadYaml(yamlFile) as YamlMap;
  final mapData =
      pubspecData.map((key, value) => MapEntry(key.toString(), value));
  return (mapData['format'] as Map?)?['line_length'] as int? ?? 80;
}
