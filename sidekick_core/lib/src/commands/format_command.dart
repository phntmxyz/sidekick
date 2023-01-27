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

  /// glob patterns of packages whose dependencies should not be loaded
  ///
  /// Search starts at repository root.
  ///
  /// Example project layout:
  ///
  /// ```
  /// project-root
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
    argParser.addFlag(
      'verify',
      help: 'Only verifies that all code is formatted, does not actually format it',
    );
  }

  @override
  Future<void> run() async {
    final String? packageName = argResults?['package'] as String?;
    final int? lineLength = int.tryParse(argResults?['line-length'] as String? ?? '');
    final bool verify = argResults?['verify'] as bool? ?? false;

    final root = SidekickContext.projectRoot;
    final List<DartPackage> allPackages = findAllPackages(root);
    if (packageName != null) {
      final package = allPackages.where((it) => it.name == packageName).firstOrNull;
      if (package == null) {
        throw "Package with name $packageName not found in repository "
            "${SidekickContext.repository?.path}";
      }
      // only format for selected package
      // _format(package, globalLineLength: lineLength);
      return;
    }
    final globExcludes = excludeGlob
        .expand((rule) {
          // start search at repo root
          return Glob("${root.path}/$rule").listSync(root: root.path);
        })
        .whereType<Directory>()
        .mapNotNull((e) => DartPackage.fromDirectory(e));

    final excluded = [
      ...globExcludes,
    ];

    // Key: line length
    // Value: all files to be formatted with the line length specified by key

    // Getting all Dart files exluding files which are starting with a .
    final allFiles = SidekickContext.projectRoot
        .listSync(recursive: true)
        .whereType<File>()
        .filter((file) => file.extension == '.dart')
        .filter(
          (file) => file.uri.pathSegments.none(
            (element) => element.startsWith('.'),
          ),
        )
        .toList();

    // Getting all directories excluding directories which are starting with a . and sort them by length
    final sortedPackages = allPackages.sortedByDescending((element) => element.root.path.length);

    final lineLengthsAndFiles = <int, List<File>>{};

    for (final package in sortedPackages) {
      final lineLength = getLineLength(package);
      final filesInPackage = allFiles.where((file) => file.path.contains(package.root.path)).toList();
      allFiles.removeWhere((file) => filesInPackage.contains(file));
      (lineLengthsAndFiles[lineLength] ??= []).addAll(filesInPackage);
    }

    // exclude files from excludeGlob
    final excludedFiles = excludeGlob.expand(
      (rule) => Glob("${root.path}/$rule").listSync(root: root.path).whereType<File>(),
    );
    for (final files in lineLengthsAndFiles.values) {
      files.removeWhere(
        (file) => excludedFiles.any((excludedFile) => file.path == excludedFile.path),
      );
    }

    if (lineLength != null) {
      final tempMap = [...lineLengthsAndFiles.values];
      lineLengthsAndFiles.clear();
      (lineLengthsAndFiles[lineLength] ??= []).addAll(tempMap.expand((e) => e));
    }
    _format(lineLengthsAndFiles, verify: verify);
  }
}

void _format(
  Map<int, Iterable<File>> filesWithLineLength, {
  bool verify = false,
}) {
  for (final entry in filesWithLineLength.entries) {
    final exitCode = dart(
      [
        'format',
        '-l',
        '${entry.key}',
        ...entry.value.map((file) => file.path),
        if (verify) '--set-exit-if-changed',
      ],
    );
    if (exitCode != 0) {
      throw "Formatting failed with exit code $exitCode";
    }
    print("\n");
  }
}

@visibleForTesting
int getLineLength(DartPackage package) {
  final yamlFile = package.root.file('pubspec.yaml').readAsStringSync();
  final pubspecData = loadYaml(yamlFile) as YamlMap;
  final mapData = pubspecData.map((key, value) => MapEntry(key.toString(), value));
  return (mapData['format'] as Map?)?['line_length'] as int? ?? 80;
}
