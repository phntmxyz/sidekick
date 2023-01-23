import 'dart:math';

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

    final List<DartPackage> allPackages = repository.findAllPackages();

    if (packageName != null) {
      final package =
          allPackages.where((it) => it.name == packageName).firstOrNull;
      if (package == null) {
        throw "Package with name $packageName not found in repository "
            "${repository.root.path}";
      }
      // only format for selected package
      // _format(package, globalLineLength: lineLength);
      return;
    }
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

    // Key: line length
    // Value: all files to be formatted with the line length specified by key
    final lineLengthsAndFiles = Map.fromEntries(
      allPackages
          .filter((package) => !excluded.contains(package))
          .map((package) {
        final lineLength = getLineLength(package);
        final allFilesInPackage = package.root
            .listSync(recursive: true)
            .whereType<File>()
            .filter((file) => file.extension == '.dart')
            .filter((file) => !file.path.contains('/.dart_tool/'))
            .filter((file) => !file.path.contains('/.symlinks/'))
            .filter((file) {
          // exclude files from packages nested inside the current package
          //
          // e.g.
          // package_bar: 80
          //   package_bar_example: 120
          //
          // if this step was omitted, the result would be
          // {
          //   80: [package_bar/main.dart, package_bar/example/main.dart, ...],
          //   120: [package_bar/example/main.dart, ...],
          // }
          // that is wrong, the correct result is
          // {
          //   80: [package_bar/main.dart, ...],
          //   120: [package_bar/example/main.dart, ...],
          // }

          // get all packages except the current package in iteration
          final allOtherPackages = ([...allPackages]..remove(package));
          return allOtherPackages.any((otherPackage) {
            // does any of the other packages also contain the current file?
            if (file.path.contains(otherPackage.root.path)) {
              // exclude file if path of other package matches the file path more closely
              //
              // e.g.
              // package: packages/bar
              // otherPackage: packages/bar/example
              // file: packages/bar/example/main.dart
              //
              // otherPackage matches file path more closely,
              // so the file should be excluded for the current package

              return otherPackage.root.path.length < package.root.path.length;
            }
            return true;
          });
        });

        return MapEntry(lineLength, allFilesInPackage);
      }),
    );

    _format(lineLengthsAndFiles);
  }
}

void _format(Map<int, Iterable<File>> filesWithLineLength) {
  filesWithLineLength.entries.map((e) {
    final exitCode = dart(
      [
        'format',
        '-l',
        '${e.key}',
        ...e.value.map(
          (e) => e.path,
        ),
      ],
    );
    if (exitCode != 0) {
      throw "Formatting failed with exit code $exitCode";
    }
    print("\n");
  });
}

@visibleForTesting
int getLineLength(DartPackage package) {
  final yamlFile = package.root.file('pubspec.yaml').readAsStringSync();
  final pubspecData = loadYaml(yamlFile) as YamlMap;
  final mapData =
      pubspecData.map((key, value) => MapEntry(key.toString(), value));
  return (mapData['format'] as Map?)?['line_length'] as int? ?? 80;
}
