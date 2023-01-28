import 'package:glob/glob.dart';
import 'package:meta/meta.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:yaml/yaml.dart';

/// Formats the Code for all Flutter/Dart packages in the repository
class FormatCommand extends Command {
  @override
  String get description => 'Formatting the code for all packages';

  @override
  String get name => 'format';

  /// glob patterns of packages whose files should not be formatted.
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
      help:
          'Only verifies that all code is formatted, does not actually format it',
    );
  }

  @override
  Future<void> run() async {
    final String? packageName = argResults?['package'] as String?;
    final int? lineLength =
        int.tryParse(argResults?['line-length'] as String? ?? '');
    final bool verify = argResults?['verify'] as bool? ?? false;

    final root = SidekickContext.projectRoot;
    final List<DartPackage> allPackages = findAllPackages(root);
    final globExcludes =
        excludeGlob.map<Glob>((rule) => Glob("${root.path}/$rule"));
    if (packageName != null) {
      final package =
          allPackages.where((it) => it.name == packageName).firstOrNull;
      if (package == null) {
        throw "Package with name $packageName not found in repository "
            "${SidekickContext.repository?.path}";
      }
      final int lineLength = getLineLength(package);
      final allDartFiles =
          package.root.listSync(recursive: true).filterAllFiles(globExcludes);
      _format({lineLength: allDartFiles}, verify: verify);
      return;
    }

    // Getting all Dart files excluding files that are starting with "."
    final allFiles = SidekickContext.projectRoot
        .listSync(recursive: true)
        .filterAllFiles(globExcludes)
        .toList();

    // Getting all directories excluding directories which are starting with a . and sort them by length
    final sortedPackages =
        allPackages.sortedByDescending((element) => element.root.path.length);

    final lineLengthsAndFiles = <int, List<File>>{};

    for (final package in sortedPackages) {
      final resolvedLineLength = lineLength ?? getLineLength(package);
      final filesInPackage = allFiles
          .where((file) => file.path.contains(package.root.path))
          .toList();
      for (final file in filesInPackage) {
        allFiles.remove(file);
      }
      if (filesInPackage.isNotEmpty) {
        (lineLengthsAndFiles[resolvedLineLength] ??= []).addAll(filesInPackage);
      }
    }
    _format(lineLengthsAndFiles, verify: verify);
  }
}

extension on Iterable<FileSystemEntity> {
  Iterable<File> filterAllFiles(Iterable<Glob> globExcludes) {
    return whereType<File>()
        .filter((file) => file.extension == '.dart')
        .filter(
          (file) => file.uri.pathSegments.none(
            (element) => element.startsWith('.'),
          ),
        )
        .whereNot(
          (file) => globExcludes.any(
            (glob) => glob.matches(file.path),
          ),
        );
  }
}

void _format(
  Map<int, Iterable<File>> filesWithLineLength, {
  bool verify = false,
}) {
  // remove map entries with 0 files, otherwise the `format` command crashes
  // because it expects at least one file or directory
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
  final mapData =
      pubspecData.map((key, value) => MapEntry(key.toString(), value));
  return (mapData['format'] as Map?)?['line_length'] as int? ?? 80;
}
