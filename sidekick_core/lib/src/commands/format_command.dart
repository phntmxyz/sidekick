import 'package:glob/glob.dart';
import 'package:meta/meta.dart';
import 'package:sidekick_core/sidekick_core.dart';
import 'package:yaml/yaml.dart';

/// Formats the Code for all Flutter/Dart packages in the repository
///
/// You can specify the line length per package in the pubspec.yaml. When not
/// specified the default line length of 80 is used.
///
/// ```yaml
/// name: my_package
///
/// format:
///   line_length: 120
/// ```
class FormatCommand extends Command {
  @override
  String get description => 'Formats all Dart files in the repository.';

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

  /// The default line length to be used when format.line_length is not
  /// specified in pubspec.yaml.
  final int defaultLineLength;

  /// When true, generated files (`.g.dart`, or `.freezed.dart`) formatted as well.
  final bool formatGenerated;

  FormatCommand({
    this.excludeGlob = const [],
    this.defaultLineLength = 80,
    this.formatGenerated = true,
  }) {
    argParser.addOption(
      'package',
      abbr: 'p',
    );
    argParser.addFlag(
      'verify',
      help:
          'Only verifies that all code is formatted, does not actually format it',
    );
  }

  bool foundFormatError = false;

  @override
  Future<void> run() async {
    final String? packageName = argResults?['package'] as String?;
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
      final int lineLength = getLineLength(package) ?? defaultLineLength;
      final allDartFiles = package.root.findFilesToFormat(globExcludes);
      final withoutGenerated = filterGeneratedFiles(allDartFiles).toList();
      _format(
        name: "package:${package.name}",
        lineLength: lineLength,
        files: withoutGenerated,
        verify: verify,
      );
      _verifyThrow();
      return;
    }

    final allFiles =
        SidekickContext.projectRoot.findFilesToFormat(globExcludes).toList();
    final withoutGenerated = filterGeneratedFiles(allFiles).toList();

    final sortedPackages =
        allPackages.sortedByDescending((element) => element.root.path.length);

    for (final package in sortedPackages) {
      final resolvedLineLength = getLineLength(package) ?? defaultLineLength;
      final filesInPackage = withoutGenerated
          .where((file) => file.path.contains(package.root.path))
          .toList();
      for (final file in filesInPackage) {
        withoutGenerated.remove(file);
      }
      _format(
        name: "package:${package.name}",
        lineLength: resolvedLineLength,
        files: filesInPackage,
        verify: verify,
      );
    }
    if (withoutGenerated.isNotEmpty) {
      _format(
        name: "Other",
        lineLength: defaultLineLength,
        files: withoutGenerated,
        verify: verify,
      );
    }
    _verifyThrow();
  }

  void _verifyThrow() {
    final bool verify = argResults?['verify'] as bool? ?? false;
    if (verify && foundFormatError) {
      throw DartFileFormatException(
        'Dart files are not correctly formatted. '
        'Run "${SidekickContext.cliName} sidekick format" to format the code.',
      );
    }
  }

  void _format({
    required String name,
    required int lineLength,
    required Iterable<File> files,
    bool verify = false,
  }) {
    if (verify) {
      print("Verifying $name");
    } else {
      print("Formatting $name");
    }
    if (files.isEmpty) {
      print("No files to format");
      return;
    }
    final exitCode = dart(
      [
        'format',
        '-l',
        '$lineLength',
        if (!verify) '--fix',
        ...files.map((file) => file.path),
        if (verify) '--set-exit-if-changed',
        if (verify) '--output=none',
      ],
      nothrow: verify,
    );
    if (exitCode != 0) {
      foundFormatError = true;
    }
  }

  Iterable<File> filterGeneratedFiles(Iterable<File> files) {
    if (formatGenerated) return files;
    return files
        .where(
          (file) =>
              !file.path.endsWith('.g.dart') &&
              !file.path.endsWith('.freezed.dart'),
        )
        .toList();
  }
}

extension on Directory {
  Iterable<File> findFilesToFormat(Iterable<Glob> globExcludes) {
    /// Returns `true` if [dir] is not a package build directory.
    bool isBuildDirectory(Directory dir) {
      if (dir.name == 'build') {
        // keep folders named 'build' unless they are in the root of a
        // DartPackage (which means they've been generated by that package)
        final package = DartPackage.fromDirectory(dir.parent);
        if (package != null) {
          // ignore <dartPackage>/build dir
          return true;
        }
      }
      return false;
    }

    /// Returns `true` if [file] is not in a hidden directory.
    bool isInHiddenDirectory(FileSystemEntity file) {
      final relativePath = Uri.parse(relative(file.path, from: path));
      return relativePath.pathSegments.any((dir) => dir.startsWith('.'));
    }

    final directories = allSubDirectories((dir) {
      if (isBuildDirectory(dir)) {
        return false;
      }
      if (isInHiddenDirectory(dir)) {
        return false;
      }
      return true;
    });

    /// Returns `true` if [file] is excluded by [globExcludes]
    bool isExcluded(File file) {
      return globExcludes.any((glob) => glob.matches(file.path));
    }

    return directories
        .flatMap((dir) => dir.listSync())
        .whereType<File>()
        .filter((file) => file.extension == '.dart')
        .whereNot(isExcluded);
  }
}

@visibleForTesting
int? getLineLength(DartPackage package) {
  final yamlFile = package.root.file('pubspec.yaml').readAsStringSync();
  final pubspecData = loadYaml(yamlFile) as YamlMap;
  final mapData =
      pubspecData.map((key, value) => MapEntry(key.toString(), value));
  return (mapData['format'] as Map?)?['line_length'] as int?;
}

class DartFileFormatException implements Exception {
  final String message;

  DartFileFormatException(this.message);
}
