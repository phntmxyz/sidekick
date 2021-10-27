import 'dart:io';
import 'package:dartx/dartx_io.dart';

/// Detects project structure and generates a representation in code
class ProjectStructureDetector {
  ProjectStructure detectProjectType(Directory dir) {
    print('Analyzing project in ${dir.path}');
    final pubspec = dir.file('pubspec.yaml');
    bool hasToplevelPubspecYaml = pubspec.existsSync();

    final packagesDir = dir.directory('packages');
    bool hasPackagesDir = packagesDir.existsSync();

    if (hasToplevelPubspecYaml && !hasPackagesDir) {
      return ProjectStructure.simple;
    }

    if (!hasToplevelPubspecYaml && hasPackagesDir) {
      return ProjectStructure.multi_package;
    }

    if (hasToplevelPubspecYaml && hasPackagesDir) {
      return ProjectStructure.root_with_packages;
    }

    return ProjectStructure.unknown;
  }
}

/// The project structure in this repository
enum ProjectStructure {
  /// A plain dart/flutter project with a single pubspec.yaml
  simple,

  /// Repo with a top-level `packages` directory, containing all packages
  multi_package,

  /// A single flutter project in root, with multiple packages in `packages`
  root_with_packages,

  /// A, so far, unknown project structure
  unknown,
}
