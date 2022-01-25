import 'dart:io';
import 'package:dartx/dartx_io.dart';

/// Detects project structure and generates a representation in code
class ProjectStructureDetector {
  ProjectStructure detectProjectType(Directory dir) {
    print('Analyzing project structure in ${dir.path}');
    final pubspec = dir.file('pubspec.yaml');
    final hasToplevelPubspecYaml = pubspec.existsSync();

    final packagesDir = dir.directory('packages');
    final hasPackagesDir = packagesDir.existsSync();

    if (hasToplevelPubspecYaml && !hasPackagesDir) {
      return ProjectStructure.simple;
    }

    if (!hasToplevelPubspecYaml && hasPackagesDir) {
      return ProjectStructure.multiPackage;
    }

    if (hasToplevelPubspecYaml && hasPackagesDir) {
      return ProjectStructure.rootWithPackages;
    }

    return ProjectStructure.unknown;
  }
}

/// The project structure in this repository
enum ProjectStructure {
  /// A plain dart/flutter project with a single pubspec.yaml
  simple,

  /// Repo with a top-level `packages` directory, containing all packages
  multiPackage,

  /// A single flutter project in root, with multiple packages in `packages`
  rootWithPackages,

  /// A, so far, unknown project structure
  unknown,
}
